#!/usr/bin/env bash
set -euo pipefail

allowlist=${GITHUB_WRITE_OWNERS_FILE:-$HOME/.config/agentbox/github-write-owners}
remote_name=${1:-}
remote_url=${2:-}

case "$remote_url" in
  git@github.com:*|ssh://git@github.com/*|https://github.com/*|http://github.com/*) ;;
  *) exit 0 ;;
esac

repo=${remote_url#git@github.com:}
repo=${repo#ssh://git@github.com/}
repo=${repo#https://github.com/}
repo=${repo#http://github.com/}
owner=${repo%%/*}

login=$(gh api user --jq .login 2>/dev/null) || {
  echo "GitHub write guard: cannot verify the authenticated account; refusing push to '$remote_name'" >&2
  exit 1
}

if [ "${owner,,}" = "${login,,}" ]; then
  exit 0
fi

if [ -f "$allowlist" ]; then
  while IFS= read -r entry || [ -n "$entry" ]; do
    entry=${entry%%#*}
    entry=${entry//[[:space:]]/}
    if [ -n "$entry" ] && [ "${owner,,}" = "${entry,,}" ]; then
      exit 0
    fi
  done < "$allowlist"
fi

echo "GitHub write guard: refusing push outside authenticated account '$login' and configured write owners (target owner: '$owner')" >&2
exit 1
