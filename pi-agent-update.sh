#!/usr/bin/env bash
# Keep the mutable personal Pi package checkout on the latest origin/main.
set -euo pipefail

repo_dir="${PI_AGENT_DIR:-${HOME}/xdev/personal/pi-agent}"
dotfiles_dir="${AGENT_DOTFILES_DIR:-${HOME}/xdev/personal/agent-dotfiles}"
dotfiles_url="$(git -C "$dotfiles_dir" remote get-url origin)"
case "$dotfiles_url" in
  git@github.com:*)
    github_path="${dotfiles_url#git@github.com:}"
    default_repo_url="https://github.com/${github_path%/*}/pi-agent.git"
    ;;
  ssh://git@github.com/*)
    github_path="${dotfiles_url#ssh://git@github.com/}"
    default_repo_url="https://github.com/${github_path%/*}/pi-agent.git"
    ;;
  *)
    default_repo_url="${dotfiles_url%/*}/pi-agent.git"
    ;;
esac
repo_url="${PI_AGENT_REPOSITORY_URL:-$default_repo_url}"
state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/pi-agent"
lock_marker="${state_dir}/package-lock.sha256"
quiet="${PI_AGENT_UPDATE_QUIET:-0}"

log() {
  if [ "$quiet" != 1 ]; then
    printf '%s\n' "$*"
  fi
}

mkdir -p "$(dirname "$repo_dir")" "$state_dir"
chmod 700 "$state_dir"
exec 9>"$state_dir/update.lock"
flock 9

if [ ! -e "$repo_dir" ]; then
  log "==> cloning pi-agent main"
  if [ "$quiet" = 1 ]; then
    git clone --quiet --branch main --single-branch "$repo_url" "$repo_dir"
  else
    git clone --branch main --single-branch "$repo_url" "$repo_dir"
  fi
elif [ ! -d "$repo_dir/.git" ]; then
  echo "pi-agent path exists but is not a Git checkout: $repo_dir" >&2
  exit 1
fi

if [ "$(git -C "$repo_dir" branch --show-current)" != "main" ]; then
  echo "pi-agent checkout must be on main: $repo_dir" >&2
  exit 1
fi
if ! git -C "$repo_dir" diff --quiet || ! git -C "$repo_dir" diff --cached --quiet; then
  echo "pi-agent checkout is dirty; refusing to overwrite local work: $repo_dir" >&2
  exit 1
fi

current_revision="$(git -C "$repo_dir" rev-parse HEAD)"
git -C "$repo_dir" fetch --quiet "$repo_url" main:refs/remotes/origin/main
latest_revision="$(git -C "$repo_dir" rev-parse origin/main)"
if [ "$current_revision" != "$latest_revision" ]; then
  log "==> updating pi-agent main"
  git -C "$repo_dir" merge --quiet --ff-only origin/main
fi

lock_hash="$(sha256sum "$repo_dir/package-lock.json" | cut -d ' ' -f 1)"
installed_hash="$(cat "$lock_marker" 2>/dev/null || true)"
if [ ! -d "$repo_dir/node_modules" ] || [ "$installed_hash" != "$lock_hash" ]; then
  log "==> installing pi-agent dependencies"
  if [ "$quiet" = 1 ]; then
    npm --prefix "$repo_dir" ci --legacy-peer-deps --loglevel=error
  else
    npm --prefix "$repo_dir" ci --legacy-peer-deps
  fi
  printf '%s\n' "$lock_hash" > "$lock_marker.tmp"
  mv "$lock_marker.tmp" "$lock_marker"
  chmod 600 "$lock_marker"
fi

log "pi-agent is current at $(git -C "$repo_dir" rev-parse --short HEAD)"
