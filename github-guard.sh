#!/usr/bin/env bash
set -euo pipefail

real_gh=$1
allowlist=$2
shift 2

die() {
  printf 'GitHub write guard: %s\n' "$*" >&2
  exit 1
}

login() {
  local value
  value=$("$real_gh" api user --jq .login 2>/dev/null) ||
    die "cannot verify the authenticated GitHub account; refusing mutation"
  [ -n "$value" ] || die "authenticated GitHub account has no login; refusing mutation"
  printf '%s\n' "$value"
}

repo_arg() {
  local previous="" arg
  for arg in "$@"; do
    if [ "$previous" = repo ]; then printf '%s\n' "$arg"; return; fi
    case "$arg" in
      -R|--repo) previous=repo ;;
      --repo=*) printf '%s\n' "${arg#--repo=}"; return ;;
      *) previous="" ;;
    esac
  done
}

owner_from_repo() {
  local repo=$1
  repo=${repo#https://github.com/}
  repo=${repo#http://github.com/}
  repo=${repo#ssh://git@github.com/}
  repo=${repo#git@github.com:}
  repo=${repo%.git}
  case "$repo" in */*) printf '%s\n' "${repo%%/*}" ;; *) return 1 ;; esac
}

assert_owner() {
  local target_owner=$1 account entry
  account=$(login)
  if [ "${target_owner,,}" = "${account,,}" ]; then
    return
  fi
  if [ -f "$allowlist" ]; then
    while IFS= read -r entry || [ -n "$entry" ]; do
      entry=${entry%%#*}
      entry=${entry//[[:space:]]/}
      if [ -n "$entry" ] && [ "${target_owner,,}" = "${entry,,}" ]; then
        return
      fi
    done < "$allowlist"
  fi
  die "refusing mutation outside authenticated account '$account' and configured write owners (target owner: '$target_owner')"
}

assert_repo_target() {
  local explicit current
  explicit=$(repo_arg "$@")
  if [ -n "$explicit" ]; then
    assert_owner "$(owner_from_repo "$explicit" || die "cannot determine repository owner from '$explicit'")"
    return
  fi
  current=$("$real_gh" repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) ||
    die "cannot determine the target repository; use --repo OWNER/REPO"
  assert_owner "$(owner_from_repo "$current" || die "cannot determine repository owner from '$current'")"
}

assert_pr_create_target() {
  local explicit parent
  explicit=$(repo_arg "$@")
  if [ -n "$explicit" ]; then
    assert_owner "$(owner_from_repo "$explicit" || die "cannot determine repository owner from '$explicit'")"
    return
  fi
  # In a fork, `gh pr create` targets the parent by default.
  parent=$("$real_gh" repo view --json parent --jq '.parent.nameWithOwner // empty' 2>/dev/null) ||
    die "cannot determine the pull request base repository"
  if [ -n "$parent" ]; then
    assert_owner "$(owner_from_repo "$parent" || die "cannot determine parent repository owner")"
  else
    assert_repo_target "$@"
  fi
}

assert_named_owner() {
  local previous="" arg owner=""
  for arg in "$@"; do
    if [ "$previous" = owner ]; then owner=$arg; break; fi
    case "$arg" in
      --owner|--org) previous=owner ;;
      --owner=*|--org=*) owner=${arg#*=}; break ;;
      *) previous="" ;;
    esac
  done
  if [ -n "$owner" ]; then assert_owner "$owner"; else assert_repo_target "$@"; fi
}

api_is_mutation() {
  local method="" has_fields=0 graphql=0 query="" previous="" arg
  [ "${1:-}" = graphql ] && graphql=1
  for arg in "$@"; do
    case "$previous" in
      method) method=$arg; previous=""; continue ;;
      query) query=$arg; previous=""; continue ;;
    esac
    case "$arg" in
      -X|--method) previous=method ;;
      --method=*) method=${arg#*=} ;;
      -f|-F|--field|--raw-field|--input) has_fields=1 ;;
      -fquery=*|-Fquery=*|--field=query=*|--raw-field=query=*) has_fields=1; query=${arg#*=} ;;
    esac
  done
  method=${method^^}
  if [ "$graphql" -eq 1 ]; then
    case "$query" in *mutation*) return 0 ;; "") [ "$has_fields" -eq 1 ]; return ;; *) return 1 ;; esac
  fi
  case "$method" in GET|HEAD) return 1 ;; POST|PUT|PATCH|DELETE) return 0 ;; esac
  [ "$has_fields" -eq 1 ]
}

assert_api_target() {
  local endpoint="" arg owner previous=""
  for arg in "$@"; do
    if [ -n "$previous" ]; then previous=""; continue; fi
    case "$arg" in
      -X|--method|-f|-F|--field|--raw-field|--input|--jq|-q|--template|-t|--hostname) previous=value ;;
      --method=*|--field=*|--raw-field=*|--jq=*|--template=*|--hostname=*) ;;
      graphql) die "raw GraphQL mutations are blocked; use a guarded gh command" ;;
      -*) ;;
      *) endpoint=$arg; break ;;
    esac
  done
  case "$endpoint" in
    repos/'{owner}'/'{repo}'*) assert_repo_target "$@" ;;
    repos/*/*|/repos/*/*)
      endpoint=${endpoint#/}; endpoint=${endpoint#repos/}; owner=${endpoint%%/*}
      assert_owner "$owner"
      ;;
    *) die "cannot prove the raw API mutation targets an owned repository" ;;
  esac
}

[ "$#" -gt 0 ] || exec "$real_gh"
command=$1
subcommand=${2:-}

case "$command:$subcommand" in
  api:graphql) if api_is_mutation "${@:2}"; then assert_api_target "${@:2}"; fi ;;
  api:*) if api_is_mutation "${@:2}"; then assert_api_target "${@:2}"; fi ;;
  pr:create) assert_pr_create_target "${@:2}" ;;
  pr:close|pr:comment|pr:edit|pr:lock|pr:merge|pr:ready|pr:reopen|pr:review|pr:unlock) assert_repo_target "${@:2}" ;;
  issue:create|issue:close|issue:comment|issue:delete|issue:edit|issue:lock|issue:pin|issue:reopen|issue:transfer|issue:unlock|issue:unpin) assert_repo_target "${@:2}" ;;
  run:cancel|run:delete|run:rerun) assert_repo_target "${@:2}" ;;
  workflow:disable|workflow:enable|workflow:run) assert_repo_target "${@:2}" ;;
  release:create|release:delete|release:delete-asset|release:edit|release:upload) assert_repo_target "${@:2}" ;;
  label:clone|label:create|label:delete|label:edit) assert_repo_target "${@:2}" ;;
  secret:delete|secret:set|variable:delete|variable:set) assert_named_owner "${@:2}" ;;
  project:create|project:close|project:copy|project:delete|project:edit|project:item-add|project:item-archive|project:item-create|project:item-delete|project:item-edit|project:link|project:mark-template|project:unlink) assert_named_owner "${@:2}" ;;
  repo:archive|repo:delete|repo:edit|repo:rename|repo:sync)
    target=$(repo_arg "${@:2}"); [ -n "$target" ] || target=${3:-}
    if [ -n "$target" ] && [[ "$target" == */* ]]; then assert_owner "$(owner_from_repo "$target")"; else assert_repo_target "${@:2}"; fi
    ;;
  repo:create)
    target=${2:-}; if [[ "$target" == */* ]]; then assert_owner "$(owner_from_repo "$target")"; else login >/dev/null; fi
    ;;
  repo:fork|gist:create|gist:delete|gist:edit|gist:rename|gpg-key:add|gpg-key:delete|ssh-key:add|ssh-key:delete) login >/dev/null ;;

  # Explicitly read-only or local-only commands.
  auth:*|alias:*|browse:*|completion:*|config:*|extension:*|help:*|search:*|status:*|version:*|pr:checks|pr:diff|pr:list|pr:status|pr:view|pr:checkout|issue:list|issue:status|issue:view|run:download|run:list|run:view|run:watch|workflow:list|workflow:view|release:download|release:list|release:verify|release:view|repo:clone|repo:list|repo:view|label:list|secret:list|variable:list|project:list|project:view|project:item-list|project:field-list|gist:clone|gist:list|gist:view|gpg-key:list|ssh-key:list) ;;
  *) die "unclassified gh command '$command $subcommand'; refusing because it may mutate GitHub" ;;
esac

exec "$real_gh" "$@"
