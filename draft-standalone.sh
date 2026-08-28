#!/usr/bin/env bash
set -euo pipefail

config_dir="$HOME/.config/draft-standalone"
state_dir="$HOME/.local/state/draft-standalone"
backup_dir="$state_dir/backups"
compose_file="$config_dir/compose.yaml"
api_image="${DRAFT_API_IMAGE:-ghcr.io/antonve/draft-api:main}"
web_image="${DRAFT_WEB_IMAGE:-ghcr.io/antonve/draft-web:main}"

compose() {
  docker compose --file "$compose_file" "$@"
}

image_revision() {
  docker image inspect "$1" --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}'
}

verify_pair() {
  local api_revision web_revision
  api_revision="$(image_revision "$api_image")"
  web_revision="$(image_revision "$web_image")"
  if [ -z "$api_revision" ] || [ "$api_revision" != "$web_revision" ]; then
    echo "Draft API revision '$api_revision' does not match web revision '$web_revision'." >&2
    return 1
  fi
  printf '%s\n' "$api_revision"
}

restore_image_tag() {
  local image="$1"
  local previous_id="$2"
  if [ -n "$previous_id" ]; then
    docker image tag "$previous_id" "$image"
  fi
}

initialize() {
  install -d -m 0700 "$config_dir/secrets" "$state_dir" "$backup_dir" "$HOME/.local/bin"
  if [ ! -s "$config_dir/secrets/postgres-password" ]; then
    secret_tmp="$(mktemp "$config_dir/secrets/.postgres-password.XXXXXX")"
    openssl rand -hex 32 >"$secret_tmp"
    chmod 0444 "$secret_tmp"
    mv "$secret_tmp" "$config_dir/secrets/postgres-password"
  fi
  chmod 0700 "$config_dir/secrets"
  chmod 0444 "$config_dir/secrets/postgres-password"
}

install_cli() (
  set -euo pipefail
  cli_tmp="$(mktemp -d "$state_dir/cli.XXXXXX")"
  cli_container=""
  trap 'if [ -n "$cli_container" ]; then docker rm "$cli_container" >/dev/null 2>&1 || true; fi; rm -rf -- "$cli_tmp"' EXIT
  cli_container="$(docker create "$api_image")"
  docker cp "$cli_container:/app/draft" "$cli_tmp/draft"
  install -m 0555 "$cli_tmp/draft" "$HOME/.local/bin/.draft.new"
  mv "$HOME/.local/bin/.draft.new" "$HOME/.local/bin/draft"
)

backup() {
  initialize
  if [ -z "$(compose ps --status running --quiet postgres)" ]; then
    echo "Draft PostgreSQL is not running; skipping backup."
    return 0
  fi
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_tmp="$backup_dir/.draft-${timestamp}.dump.tmp"
  backup_path="$backup_dir/draft-${timestamp}.dump"
  compose exec --no-TTY postgres pg_dump \
    --username=draft --dbname=draft --format=custom >"$backup_tmp"
  chmod 0600 "$backup_tmp"
  mv "$backup_tmp" "$backup_path"
  find "$backup_dir" -maxdepth 1 -type f -name 'draft-*.dump' -mtime +14 -delete
  echo "Draft backup: $backup_path"
}

up() {
  initialize
  if ! docker image inspect "$api_image" "$web_image" >/dev/null 2>&1; then
    compose pull api web migrate
  fi
  verify_pair >/dev/null
  compose up --detach --wait --wait-timeout 300
  install_cli
}

update() {
  initialize
  exec 9>"$state_dir/update.lock"
  if ! flock --nonblock 9; then
    echo "A Draft update is already running."
    return 0
  fi
  backup
  previous_api_id="$(docker image inspect "$api_image" --format '{{ .Id }}' 2>/dev/null || true)"
  previous_web_id="$(docker image inspect "$web_image" --format '{{ .Id }}' 2>/dev/null || true)"
  if ! compose pull api web migrate; then
    restore_image_tag "$api_image" "$previous_api_id"
    restore_image_tag "$web_image" "$previous_web_id"
    return 1
  fi
  if ! revision="$(verify_pair)"; then
    restore_image_tag "$api_image" "$previous_api_id"
    restore_image_tag "$web_image" "$previous_web_id"
    echo "Refusing Draft update; restored the previous local image tags." >&2
    return 1
  fi
  up
  echo "Draft updated to $revision."
}

case "${1:-}" in
  init) initialize ;;
  up) up ;;
  update) update ;;
  backup) backup ;;
  down) compose down ;;
  status) compose ps ;;
  logs) shift; compose logs --follow "$@" ;;
  *)
    echo "usage: draft-standalone <init|up|update|backup|down|status|logs>" >&2
    exit 2
    ;;
esac
