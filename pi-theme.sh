theme_file="$HOME/.config/agentbox/pi-theme"
settings="$HOME/.pi/agent/settings.json"

read_theme() {
  if [ -f "$theme_file" ]; then
    grep -Ev '^[[:space:]]*(#|$)' "$theme_file" | head -n 1
  fi
}

print_themes() {
  cat <<'EOF'
github-dark-default
  Blue GitHub Dark theme.
gruvbox-dark
  Warm yellow-orange Gruvbox Dark theme.
EOF
}

if [ "$#" -eq 0 ]; then
  current="$(read_theme || true)"
  printf 'Current Pi theme: %s\n\nAvailable themes:\n' "${current:-github-dark-default}"
  print_themes
  exit 0
fi

if [ "$#" -ne 1 ]; then
  echo 'usage: pi-theme [github-dark-default|gruvbox-dark]' >&2
  exit 2
fi

case "$1" in
  --list)
    print_themes
    exit 0
    ;;
  github-dark-default | gruvbox-dark)
    theme="$1"
    ;;
  *)
    echo "unknown Pi theme: $1" >&2
    print_themes >&2
    exit 2
    ;;
esac

mkdir -p "$(dirname "$theme_file")" "$(dirname "$settings")"
printf '%s\n' "$theme" > "$theme_file.tmp"
chmod 600 "$theme_file.tmp"
mv "$theme_file.tmp" "$theme_file"

if [ -f "$settings" ] && jq empty "$settings" >/dev/null 2>&1; then
  current="$(mktemp)"
  cp "$settings" "$current"
else
  current="$(mktemp)"
  printf '{}\n' > "$current"
fi
jq --arg theme "$theme" '.theme = $theme' "$current" > "$settings.tmp"
mv "$settings.tmp" "$settings"
chmod 600 "$settings"
rm -f "$current"

printf 'Selected Pi theme %s on this computer. Run /reload in existing Pi sessions.\n' "$theme"
