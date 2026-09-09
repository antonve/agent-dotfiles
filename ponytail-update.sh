#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
source_repo="DietrichGebert/ponytail"

# Bootstrap activates Home Manager before installing the harness CLIs. Its
# subsequent agentbox-update runs this helper again with both CLIs available.
if command -v codex >/dev/null; then
  marketplaces=$(codex plugin marketplace list --json)
  if jq -e '.marketplaces | any(.name == "ponytail")' <<< "$marketplaces" >/dev/null; then
    codex plugin marketplace upgrade ponytail
  else
    codex plugin marketplace add "$source_repo"
  fi
  codex plugin add ponytail@ponytail
else
  echo "Ponytail: Codex setup deferred until agentbox-update."
fi

if command -v claude >/dev/null; then
  marketplaces=$(claude plugin marketplace list --json)
  if jq -e 'any(.name == "ponytail")' <<< "$marketplaces" >/dev/null; then
    claude plugin marketplace update ponytail
  else
    claude plugin marketplace add "$source_repo"
  fi
  plugins=$(claude plugin list --json)
  if jq -e 'any(.id == "ponytail@ponytail" and .scope == "user")' <<< "$plugins" >/dev/null; then
    claude plugin update ponytail@ponytail --scope user
  else
    claude plugin install ponytail@ponytail --scope user
  fi
  if ! jq -e '.enabledPlugins["ponytail@ponytail"] == true' "$HOME/.claude/settings.json" >/dev/null; then
    claude plugin enable ponytail@ponytail --scope user
  fi
else
  echo "Ponytail: Claude setup deferred until agentbox-update."
fi

# Install eagerly so OpenCode can load the adapter without an initial download.
# Keep its package separate from OpenCode's own dependencies.
package_dir="$HOME/.local/share/agentbox/ponytail"
npm install --prefix "$package_dir" --ignore-scripts --no-audit --no-fund \
  @dietrichgebert/ponytail@latest < /dev/null
plugin="$package_dir/node_modules/@dietrichgebert/ponytail/.opencode/plugins/ponytail.mjs"
test -s "$plugin"
settings="$HOME/.config/opencode/opencode.json"
mkdir -p "$(dirname "$settings")"
if [ ! -f "$settings" ]; then
  printf '{}\n' > "$settings"
fi
jq --arg plugin "$plugin" '
  .plugin = (((.plugin // []) | map(select(
    . != $plugin and . != "@dietrichgebert/ponytail" and
    (startswith("@dietrichgebert/ponytail@") | not)
  ))) + [$plugin])
' "$settings" > "$settings.tmp"
chmod 600 "$settings.tmp"
mv "$settings.tmp" "$settings"

echo "Ponytail installed. Start new agent sessions; review Codex plugin hooks in /hooks."
