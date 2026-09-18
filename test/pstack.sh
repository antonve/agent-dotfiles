#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
plugin="$repo_root/plugins/pstack-agentbox"
marketplace="$repo_root/.agents/plugins/marketplace.json"

jq -e '.name == "pstack-agentbox" and .skills == "./skills/"' \
  "$plugin/.codex-plugin/plugin.json" >/dev/null
jq -e '.name == "agent-dotfiles" and (.plugins | any(
  .name == "pstack-agentbox" and .source.path == "./plugins/pstack-agentbox"
))' "$marketplace" >/dev/null

skill_count=$(find "$plugin/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | wc -l)
[ "$skill_count" -eq 45 ]

for excluded in bro make-bot-ui setup-benny; do
  [ ! -e "$plugin/skills/$excluded" ]
done
[ ! -e "$plugin/automations/benny" ]
[ ! -e "$plugin/skills/poteto-mode/playbooks/shipping.md" ]
[ ! -e "$plugin/skills/poteto-mode/playbooks/autopilot-stack.md" ]
[ ! -e "$plugin/skills/poteto-mode/scripts/orch" ]

if rg -n 'Graphite|playbooks/(shipping|autopilot-stack)\.md|scripts/orch|\$setup-benny|\$make-bot-ui|\$bro\b' \
  "$plugin/skills" "$plugin/hooks"; then
  exit 1
fi

metadata_count=$(find "$plugin/skills" -path '*/agents/openai.yaml' -type f | wc -l)
explicit_count=$(rg -l '^  allow_implicit_invocation: false$' \
  "$plugin"/skills/*/agents/openai.yaml | wc -l)
[ "$metadata_count" -eq "$skill_count" ]
[ "$explicit_count" -eq "$skill_count" ]

rg -q '\$draft-review-workflow' \
  "$plugin/skills/poteto-mode/playbooks/multi-phase-plan.md"
rg -q 'pstack-agentbox' "$plugin/hooks/scripts/poteto-mode-state.mjs"

while IFS= read -r reference; do
  [ -f "$plugin/skills/poteto-mode/$reference" ]
done < <(
  rg -o 'playbooks/[a-z0-9-]+\.md' "$plugin/skills/poteto-mode" \
    --glob '*.md' | sed 's/.*://' | sort -u
)
