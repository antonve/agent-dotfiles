# Agent Box

This machine is a Debian cloud agent box managed by
[agent-dotfiles](https://github.com/antonve/agent-dotfiles). The home
environment is declarative (nix + home-manager) — don't hand-edit managed
dotfiles; change the repo in `~/xdev/personal/agent-dotfiles` and run
`home-manager switch --flake ~/xdev/personal/agent-dotfiles#agent-$(uname -m)-linux --impure -b backup`.

## Worktrees: always start tasks through treehouse

When starting a new task that involves changing a repo, do NOT create branches
in the shared checkout and do NOT run `git worktree` yourself. Initialize an
isolated worktree through treehouse first:

```bash
WT=$(treehouse get --lease)   # acquire a pre-warmed worktree, print its path
cd "$WT"                      # do all work here
```

- Keep the lease while a PR is open so review feedback lands in the same
  worktree; only `treehouse return --force "$WT"` once the change is merged
  or abandoned.
- `treehouse status` shows the pool. If a repo has no pool yet, run
  `treehouse init` in the repo root once.

## Conventions

- All projects live in `~/xdev`. Clone repos there. Personal (non-work)
  repos go under `~/xdev/personal/` — they get the personal git identity.
- herdr is the terminal multiplexer; agents run inside herdr panes. When
  `HERDR_ENV=1`, use the `herdr` skill for cross-agent communication
  (spawning agents in panes, reading sibling panes, waiting on agents).
- Installed harnesses: `claude`, `codex`, `opencode`, `pi`.
- `agentbox-update` refreshes all agent CLIs and their skills.
- `add-ssh-key "<public key>"` grants SSH access for a new key.
- API keys live in `~/.config/agentbox/secrets.env` (untracked; exported into
  every shell and the herdr server). Never commit or print its contents.
- Editor: `nvim` (`vim` and `vi` are aliases for it). Common tools available:
  `gh`, `aws`, `gcloud`, `rg`, `fd`, `jq`, `fzf`, `go`, `gopls`,
  `golangci-lint`, `dlv`, `gofumpt`, `goimports`, `staticcheck`,
  `govulncheck`, and `node`.
- Herdr background shells can inherit a stale or minimal `PATH`. Before starting
  a background command, resolve its required executables and either use their
  absolute paths or begin the command with
  `export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH";`.
  Use `export` for compound commands: a bare `PATH=... command1 && command2`
  assignment applies only to `command1`. Do this especially for Nix, Home
  Manager, and Go tooling; do not retry by guessing executable locations after
  a `command not found` failure.
- Prefer the axi wrappers over the raw CLIs when they exist: `gh-axi` for
  GitHub operations, `aws-axi` for AWS, `quota-axi` for agent-provider quota.
  They are token-efficient and suggest next steps.

## Etiquette

- Prefix every agent-authored GitHub comment, review, or reply with a bold
  `**Reply by <model name>**` header, using the active model's name.
- When checking code-review comments, reply on GitHub to every relevant review
  thread with the outcome (addressed, declined with rationale, or clarification
  requested). Do not process review feedback only locally; keep the back and
  forth recorded on GitHub.
- NEVER put AI/tooling metadata in commit messages or PR descriptions: no
  session links, no `Co-Authored-By`, no "Generated with ..." lines. Commit
  messages describe the change, nothing else.
- Do not amend existing commits or force-push branches by default. Only perform
  either operation when the user explicitly requests that specific operation.
- Never stop the herdr server (`herdr server stop`) or kill its systemd unit —
  other agents run inside it.
- Don't run destructive or state-changing infrastructure commands (deploys,
  migrations, `terraform apply`) unless explicitly told to.
