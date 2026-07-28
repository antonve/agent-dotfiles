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
# restore, not sync: sync updates plugins and rewrites lazy-lock.json
if nvim --headless '+Lazy! restore' +qa >/dev/null 2>&1; then
  echo "ok   lazy.nvim restore"
else
  echo "FAIL lazy.nvim restore"
  fail=1
fi
check "lazy-lock.json untouched by plugin install" sh -c \
  'git -C "$HOME/xdev/personal/agent-dotfiles" diff --quiet -- nvim/lazy-lock.json'
check "plugins installed" sh -c 'ls "$HOME"/.local/share/nvim/lazy | grep -q kanagawa'
check "nvim leader is comma" sh -c \
  '[ "$(nvim --headless "+lua io.write(vim.g.mapleader)" +q 2>/dev/null)" = "," ]'

check "herdr user service unit" test -f "$HOME/.config/systemd/user/herdr.service"
check "bashrc auto-attaches herdr" grep -qE '^ *herdr$' "$HOME/.bashrc"
check "herdr auto-attach has file opt-out" grep -q '.no-herdr' "$HOME/.bashrc"

check "bare herdr refuses to nest inside a pane" sh -c \
  'HERDR_ENV=1 bash -ic "herdr" 2>&1 | grep -q "already inside herdr"'

check "herdr skill installed for claude" sh -c 'ls "$HOME"/.claude/skills/*herdr*/SKILL.md 2>/dev/null | grep -q .'
check "gh-axi skill installed (universal)" test -f "$HOME/.agents/skills/gh-axi/SKILL.md"
check "gh-axi session hook registered" sh -c 'grep -rq gh-axi "$HOME/.claude/settings.json"'
check "claude commit attribution disabled" sh -c \
  '[ "$(jq -r .attribution.commit "$HOME/.claude/settings.json")" = "" ]'
check "AGENTS.md forbids AI trailers" grep -qi "Co-Authored-By" "$HOME/.claude/CLAUDE.md"

check "command available: starship" command -v starship
check "bashrc inits starship" grep -q starship "$HOME/.bashrc"
check "starship config present" test -f "$HOME/.config/starship.toml"
check "starship renders pure-style prompt" sh -c \
  'cd "$HOME/xdev/personal/agent-dotfiles" && TERM=xterm-256color starship prompt --status 0 | grep -q "❯"'

check "LOCALE_ARCHIVE points at nix locale archive" sh -c \
  'bash -ic "echo \$LOCALE_ARCHIVE" 2>/dev/null | tail -1 | grep -q locale-archive'

check "secrets file created" test -f "$HOME/.config/agentbox/secrets.env"
check "secrets file is 0600" sh -c '[ "$(stat -c %a "$HOME/.config/agentbox/secrets.env")" = 600 ]'
echo 'AGENTBOX_TEST_SECRET=works' >> "$HOME/.config/agentbox/secrets.env"
check "secrets exported to shells" sh -c \
  '[ "$(bash -ic "echo \$AGENTBOX_TEST_SECRET" 2>/dev/null | tail -1)" = works ]'
check "herdr service loads secrets" grep -q 'EnvironmentFile=-.*agentbox/secrets.env' \
  "$HOME/.config/systemd/user/herdr.service"

# git aliases + settings from files/gitconfig, delta pager, lfs filters
check "git alias: co" sh -c '[ "$(git config --global --includes alias.co)" = checkout ]'
check "git alias: recent" sh -c 'git config --global --includes alias.recent | grep -q for-each-ref'
check "git push.autoSetupRemote" sh -c '[ "$(git config --global --includes push.autoSetupRemote)" = true ]'
check "git pull.rebase" sh -c '[ "$(git config --global --includes pull.rebase)" = true ]'
check "git merge.conflictstyle" sh -c '[ "$(git config --global --includes merge.conflictstyle)" = diff3 ]'
check "git diff pager is delta" sh -c 'git config --global pager.diff | grep -q delta'
check "git lfs filter configured" sh -c 'git config --global filter.lfs.clean | grep -q git-lfs'
check "command available: delta" command -v delta
check "command available: terraform" command -v terraform
check "command available: column (git recent)" command -v column

# bash aliases ported from zsh dotfiles
check "bash alias: g=git" sh -c '[ "$(bash -ic "type -t g" 2>/dev/null | tail -1)" = alias ]'
check "bash alias: x (cd ~/xdev)" sh -c 'bash -ic "alias x" 2>/dev/null | grep -q xdev'
check "bash alias: gcm" sh -c 'bash -ic "alias gcm" 2>/dev/null | grep -q "git commit -m"'
check "bash alias: cd - works" sh -c 'bash -ic "alias -- -" 2>/dev/null | grep -q "cd -"'

# git identity: default from git-identity, personal override under ~/xdev/personal
check "git-identity file created" test -f "$HOME/.config/agentbox/git-identity"
check "git-identity-personal file created" test -f "$HOME/.config/agentbox/git-identity-personal"
printf '[user]\n\tname = Work Agent\n\temail = work@example.com\n' > "$HOME/.config/agentbox/git-identity"
printf '[user]\n\temail = personal@example.com\n' > "$HOME/.config/agentbox/git-identity-personal"
mkdir -p "$HOME/xdev/identity-test" "$HOME/xdev/personal/identity-test"
git -C "$HOME/xdev/identity-test" init -q
git -C "$HOME/xdev/personal/identity-test" init -q
check "git identity: work default" sh -c \
  '[ "$(git -C "$HOME/xdev/identity-test" config user.email)" = work@example.com ]'
check "git identity: personal override" sh -c \
  '[ "$(git -C "$HOME/xdev/personal/identity-test" config user.email)" = personal@example.com ]'
check "git identity: name inherited in personal" sh -c \
  '[ "$(git -C "$HOME/xdev/personal/identity-test" config user.name)" = "Work Agent" ]'
rm -rf "$HOME/xdev/identity-test" "$HOME/xdev/personal/identity-test"

add-ssh-key "ssh-ed25519 AAAATESTKEYAAAA verify@test" >/dev/null 2>&1
check "add-ssh-key appends key" grep -q AAAATESTKEYAAAA "$HOME/.ssh/authorized_keys"
add-ssh-key "ssh-ed25519 AAAATESTKEYAAAA verify@test" >/dev/null 2>&1
check "add-ssh-key dedupes" sh -c '[ "$(grep -c AAAATESTKEYAAAA "$HOME/.ssh/authorized_keys")" = 1 ]'

exit $fail
