#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

log=$tmp/gh.log
cat > "$tmp/gh-real" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_MOCK_LOG"
case "$*" in
  "api user --jq .login") printf '%s\n' alice ;;
  "repo view --json nameWithOwner --jq .nameWithOwner") printf '%s\n' alice/project ;;
  "repo view --json parent --jq .parent.nameWithOwner // empty") printf '%s\n' "${GH_MOCK_PARENT:-}" ;;
  *) printf '%s\n' ok ;;
esac
EOF
chmod +x "$tmp/gh-real"
export GH_MOCK_LOG=$log
allowlist=$tmp/github-write-owners
: > "$allowlist"

guard() { bash "$repo_root/github-guard.sh" "$tmp/gh-real" "$allowlist" "$@"; }
expect_blocked() {
  if "$@" >"$tmp/out" 2>"$tmp/err"; then
    echo "expected command to be blocked: $*" >&2
    exit 1
  fi
  grep -q 'GitHub write guard:' "$tmp/err"
}

# Reads are unaffected.
guard pr view 1 --repo upstream/project >/dev/null

# Owned and explicitly allowlisted writes are allowed; others are blocked.
guard issue create --repo alice/project --title test >/dev/null
printf '# trusted work owner\n Work-Org # inline comment\n' > "$allowlist"
guard issue create --repo work-org/project --title test >/dev/null
expect_blocked guard issue create --repo upstream/project --title test
expect_blocked guard api repos/upstream/project/issues -f title=test
expect_blocked guard api graphql -f 'query=mutation { test }'
expect_blocked guard api --method POST graphql -f 'query=mutation { test }'

# A fork's default PR base is its external parent, so this must fail closed.
export GH_MOCK_PARENT=upstream/project
expect_blocked guard pr create --title test

# Unclassified commands fail closed rather than silently becoming a bypass.
expect_blocked guard mystery mutate --repo alice/project

# The Git wrapper rejects standard hook bypasses on pushes.
cat > "$tmp/git-real" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/git-real"
bash "$repo_root/git-guard.sh" "$tmp/git-real" status
expect_blocked bash "$repo_root/git-guard.sh" "$tmp/git-real" push --no-verify
expect_blocked bash "$repo_root/git-guard.sh" "$tmp/git-real" -c core.hooksPath=/dev/null push
expect_blocked env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null bash "$repo_root/git-guard.sh" "$tmp/git-real" push

# Pre-push permits owned GitHub remotes and rejects external ones.
mkdir "$tmp/bin"
cp "$tmp/gh-real" "$tmp/bin/gh"
PATH="$tmp/bin:$PATH" GITHUB_WRITE_OWNERS_FILE="$allowlist" bash "$repo_root/git-pre-push-guard.sh" origin git@github.com:alice/project.git
PATH="$tmp/bin:$PATH" GITHUB_WRITE_OWNERS_FILE="$allowlist" bash "$repo_root/git-pre-push-guard.sh" work https://github.com/work-org/project.git
expect_blocked env PATH="$tmp/bin:$PATH" GH_MOCK_LOG="$log" GITHUB_WRITE_OWNERS_FILE="$allowlist" bash "$repo_root/git-pre-push-guard.sh" upstream https://github.com/upstream/project.git

printf 'github guard tests passed\n'
