#!/usr/bin/env bash
set -euo pipefail

real_git=$1
shift

is_push=0
bypasses_hooks=0
previous=""
for arg in "$@"; do
  if [ "$previous" = config ]; then
    case "$arg" in core.hooksPath=*|core.hookspath=*) bypasses_hooks=1 ;; esac
    previous=""
    continue
  fi
  case "$arg" in
    push) is_push=1 ;;
    --no-verify|-n) bypasses_hooks=1 ;;
    -c) previous=config ;;
    -cCore.hooksPath=*|-ccore.hooksPath=*|-cCore.hookspath=*|-ccore.hookspath=*|--config-env=core.hooksPath:*|--config-env=core.hookspath:*) bypasses_hooks=1 ;;
  esac
done

if [ "$is_push" -eq 1 ] && [ -n "${GIT_CONFIG_COUNT:-}" ]; then
  for ((i = 0; i < GIT_CONFIG_COUNT; i++)); do
    key_var="GIT_CONFIG_KEY_$i"
    if [ "${!key_var,,}" = core.hookspath ]; then bypasses_hooks=1; fi
  done
fi

if [ "$is_push" -eq 1 ] && [ "$bypasses_hooks" -eq 1 ]; then
  echo "GitHub write guard: disabling Git hooks for push is not allowed" >&2
  exit 1
fi

exec "$real_git" "$@"
