#!/usr/bin/env bash
set -uo pipefail

readonly threshold=80
readonly command_timeout=20m

usage_percent() {
  df -P / | awk 'NR == 2 { value = $5; sub(/%$/, "", value); print value }'
}

current_usage="$(usage_percent)"
if [[ ! "$current_usage" =~ ^[0-9]+$ ]]; then
  echo "error: could not determine root filesystem usage" >&2
  exit 1
fi

lock_dir="${XDG_RUNTIME_DIR:-/tmp}"
exec 9>"$lock_dir/agentbox-disk-reclaim-${UID}.lock"
if ! flock -n 9; then
  echo "disk reclaim is already running; skipping"
  exit 0
fi

if (( current_usage <= threshold )); then
  echo "root filesystem usage is ${current_usage}%; cleanup threshold is greater than ${threshold}%; skipping"
  exit 0
fi

echo "root filesystem usage is ${current_usage}%; starting conservative cleanup"
df -hP /

run_cleanup() {
  local label="$1"
  shift
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "skip: $label ($1 is unavailable)"
    return 0
  fi

  echo "==> $label"
  local status
  if timeout --signal=TERM "$command_timeout" "$@"; then
    return 0
  else
    status=$?
  fi
  echo "warning: $label failed with status $status; continuing" >&2
  return 0
}

# Every command in this phase preserves active resources and user data.
run_cleanup "prune clean, merged, idle, unleased Treehouse worktrees" \
  treehouse prune --all --yes

if command -v docker >/dev/null 2>&1 && timeout 30s docker info >/dev/null 2>&1; then
  run_cleanup "prune unused Docker build cache" \
    docker builder prune --all --force
  run_cleanup "prune Docker images unused by any container" \
    docker image prune --all --force
else
  echo "skip: Docker cleanup (daemon is unavailable)"
fi

run_cleanup "prune dangling uv cache entries" uv cache prune
run_cleanup "prune unreferenced pnpm store packages" pnpm store prune
run_cleanup "verify and garbage-collect the npm cache" npm cache verify
run_cleanup "garbage-collect unreachable Nix store paths" nix store gc

current_usage="$(usage_percent)"
if [[ ! "$current_usage" =~ ^[0-9]+$ ]]; then
  echo "error: could not determine root filesystem usage after conservative cleanup" >&2
  exit 1
fi

if (( current_usage > threshold )); then
  echo "root filesystem usage is still ${current_usage}%; clearing rebuildable package and compiler caches"
  run_cleanup "clear the uv cache" uv cache clean
  run_cleanup "clear the npm cache" npm cache clean --force
  run_cleanup "clear the Bun package cache" bun pm cache rm
  run_cleanup "clear Go build, test, and fuzz caches" \
    go clean -cache -testcache -fuzzcache
fi

current_usage="$(usage_percent)"
echo "disk reclaim finished; root filesystem usage is ${current_usage}%"
df -hP /
if [[ "$current_usage" =~ ^[0-9]+$ ]] && (( current_usage > threshold )); then
  echo "warning: root filesystem remains above ${threshold}% after safe cleanup" >&2
fi
