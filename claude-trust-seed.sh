#!/usr/bin/env bash
# claude-trust-seed — pre-accept the Claude Code trust dialog for local project
# directories by seeding ~/.claude.json.
#
# Claude Code has no wildcard trust mechanism: trust is stored only as per
# absolute path entries under .projects["<path>"].hasTrustDialogAccepted, with
# no globbing and no parent-directory inheritance. Seeding the known project
# paths is therefore the only way to cover ~/xdev and the treehouse pool.
#
# Wired to SessionStart, so the common case (nothing new) must be cheap: one jq
# read, no write, no lock. Only when a genuinely new project dir appears does it
# take the lock and rewrite the file.
set -euo pipefail

claude_json="${HOME}/.claude.json"
[ -f "$claude_json" ] || exit 0

# Candidate project dirs: git repos one level under ~/xdev and ~/xdev/personal.
# `-e` (not `-d`) because a linked worktree's .git is a file, not a directory.
candidates=()
for d in "$HOME"/xdev/*/ "$HOME"/xdev/personal/*/; do
  [ -e "${d}.git" ] || continue
  candidates+=("$(realpath "${d%/}")")
done

# Treehouse worktrees live at /tmp/.treehouse/<repo>-<hash>/<slot>/<repo> — two
# levels below the pool dir, so a /tmp/.treehouse/*/ glob silently matches
# nothing. Each pool's treehouse-state.json authoritatively lists its worktree
# paths and stays correct if that layout ever changes.
for state in /tmp/.treehouse/*/treehouse-state.json; do
  [ -f "$state" ] || continue
  while IFS= read -r p; do
    [ -n "$p" ] && [ -d "$p" ] && candidates+=("$p")
  done < <(jq -r '(.worktrees // [])[].path // empty' "$state" 2>/dev/null || true)
done

[ "${#candidates[@]}" -gt 0 ] || exit 0

# Fast path: which candidates are not yet trusted? One read, no write.
trusted="$(jq -r '(.projects // {}) | to_entries[]
                  | select(.value.hasTrustDialogAccepted == true) | .key' \
           "$claude_json" 2>/dev/null || true)"

missing=()
for p in "${candidates[@]}"; do
  grep -qxF -- "$p" <<<"$trusted" || missing+=("$p")
done
[ "${#missing[@]}" -gt 0 ] || exit 0

# Slow path: serialize against other agent sessions on this box.
exec 9>"${HOME}/.claude.json.seed.lock"
flock -w 10 9 || exit 0

# Missing paths as a JSON array, so no path can be mangled by quoting.
paths_json="$(printf '%s\n' "${missing[@]}" \
              | jq -R -s 'split("\n") | map(select(length > 0))')"

tmp="$(mktemp "${claude_json}.seed.XXXXXX")"   # same dir => same filesystem
trap 'rm -f "$tmp"' EXIT

# Set the flag for every missing path, preserving each entry's other keys and
# the rest of the file. Replace the original only if jq exited 0 AND produced
# non-empty, valid JSON — so a failed or interrupted run can never truncate it.
if jq --argjson paths "$paths_json" '
     reduce $paths[] as $p (.; .projects[$p].hasTrustDialogAccepted = true)
   ' "$claude_json" > "$tmp" \
   && [ -s "$tmp" ] \
   && jq -e . "$tmp" >/dev/null 2>&1
then
  mv -f "$tmp" "$claude_json"   # atomic rename
  trap - EXIT
fi
exit 0
