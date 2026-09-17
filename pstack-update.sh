#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
marketplace_root="${1:-$HOME/xdev/personal/agent-dotfiles}"
marketplace_file="$marketplace_root/.agents/plugins/marketplace.json"
plugin_name="pstack-agentbox"

if ! command -v codex >/dev/null; then
  echo "pstack: Codex setup deferred until agentbox-update."
  exit 0
fi

test -f "$marketplace_file"
marketplace_name=$(jq -er '.name' "$marketplace_file")
jq -e --arg plugin "$plugin_name" '.plugins | any(.name == $plugin)' \
  "$marketplace_file" >/dev/null

desired_root=$(realpath -m "$marketplace_root")
marketplaces=$(codex plugin marketplace list --json)
configured_root=$(jq -r --arg name "$marketplace_name" \
  '.marketplaces[] | select(.name == $name) | .root' <<< "$marketplaces" | head -n 1)

if [ -z "$configured_root" ]; then
  codex plugin marketplace add "$desired_root"
elif [ "$(realpath -m "$configured_root")" != "$desired_root" ]; then
  codex plugin marketplace remove "$marketplace_name"
  codex plugin marketplace add "$desired_root"
fi

codex plugin add "$plugin_name@$marketplace_name"
echo "pstack-agentbox installed. Start a new Codex session to load its explicit skills."
