#!/usr/bin/env bash
# Run inside the test container (login shell) after bootstrap.sh.
set -uo pipefail

fail=0
check() { # check <description> <command...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   $desc"
  else
    echo "FAIL $desc"
    fail=1
  fi
}

for cmd in nvim vim vi git gh aws gcloud herdr treehouse rg fd jq fzf node go \
           add-ssh-key agentbox-update claude codex opencode pi \
           gh-axi aws-axi quota-axi \
           gopls typescript-language-server terraform-ls lua-language-server nil gcc; do
  check "command available: $cmd" command -v "$cmd"
done

check "lavish-axi is NOT installed" sh -c '! command -v lavish-axi'

check "vim is neovim" sh -c 'vim --version | head -1 | grep -qi nvim'
check "EDITOR is nvim" sh -c '[ "${EDITOR:-}" = "nvim" ]'

check "~/xdev exists" test -d "$HOME/xdev"

for f in .claude/CLAUDE.md .codex/AGENTS.md .config/opencode/AGENTS.md .pi/agent/AGENTS.md; do
  check "agent instructions: ~/$f" test -s "$HOME/$f"
done
check "AGENTS.md mentions treehouse" grep -q treehouse "$HOME/.claude/CLAUDE.md"

check "nvim config linked" test -f "$HOME/.config/nvim/init.lua"
echo "==> installing nvim plugins headlessly (lazy.nvim + treesitter)"
if nvim --headless '+Lazy! sync' +qa >/dev/null 2>&1; then
  echo "ok   lazy.nvim sync"
else
  echo "FAIL lazy.nvim sync"
  fail=1
fi
check "plugins installed" sh -c 'ls "$HOME"/.local/share/nvim/lazy | grep -q kanagawa'
check "nvim leader is comma" sh -c \
  '[ "$(nvim --headless "+lua io.write(vim.g.mapleader)" +q 2>/dev/null)" = "," ]'

check "herdr user service unit" test -f "$HOME/.config/systemd/user/herdr.service"
check "bashrc auto-attaches herdr" grep -qE '^ *herdr$' "$HOME/.bashrc"
check "herdr auto-attach has file opt-out" grep -q '.no-herdr' "$HOME/.bashrc"

check "herdr skill installed for claude" sh -c 'ls "$HOME"/.claude/skills/*herdr*/SKILL.md 2>/dev/null | grep -q .'
check "gh-axi skill installed (universal)" test -f "$HOME/.agents/skills/gh-axi/SKILL.md"
check "gh-axi session hook registered" sh -c 'grep -rq gh-axi "$HOME/.claude/settings.json"'

check "secrets file created" test -f "$HOME/.config/agentbox/secrets.env"
check "secrets file is 0600" sh -c '[ "$(stat -c %a "$HOME/.config/agentbox/secrets.env")" = 600 ]'
echo 'AGENTBOX_TEST_SECRET=works' >> "$HOME/.config/agentbox/secrets.env"
check "secrets exported to shells" sh -c \
  '[ "$(bash -ic "echo \$AGENTBOX_TEST_SECRET" 2>/dev/null | tail -1)" = works ]'
check "herdr service loads secrets" grep -q 'EnvironmentFile=-.*agentbox/secrets.env' \
  "$HOME/.config/systemd/user/herdr.service"

add-ssh-key "ssh-ed25519 AAAATESTKEYAAAA verify@test" >/dev/null 2>&1
check "add-ssh-key appends key" grep -q AAAATESTKEYAAAA "$HOME/.ssh/authorized_keys"
add-ssh-key "ssh-ed25519 AAAATESTKEYAAAA verify@test" >/dev/null 2>&1
check "add-ssh-key dedupes" sh -c '[ "$(grep -c AAAATESTKEYAAAA "$HOME/.ssh/authorized_keys")" = 1 ]'

exit $fail
