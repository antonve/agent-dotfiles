# Agent Box

This machine is a Debian cloud agent box managed by
[agent-dotfiles](https://github.com/antonve/agent-dotfiles). The home
environment is declarative (nix + home-manager) — don't hand-edit managed
dotfiles; change the repo in `~/xdev/agent-dotfiles` and run
`home-manager switch --flake ~/xdev/agent-dotfiles#agent-$(uname -m)-linux --impure -b backup`.

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

- All projects live in `~/xdev`. Clone repos there.
- herdr is the terminal multiplexer; agents run inside herdr panes. When
  `HERDR_ENV=1`, use the `herdr` skill for cross-agent communication
  (spawning agents in panes, reading sibling panes, waiting on agents).
- Installed harnesses: `claude`, `codex`, `opencode`, `pi`.
- `agentbox-update` refreshes all agent CLIs and their skills.
- `add-ssh-key "<public key>"` grants SSH access for a new key.
- API keys live in `~/.config/agentbox/secrets.env` (untracked; exported into
  every shell and the herdr server). Never commit or print its contents.
- Editor: `nvim` (`vim` and `vi` are aliases for it). Common tools available:
  `gh`, `aws`, `gcloud`, `rg`, `fd`, `jq`, `fzf`, `go`, `node`.
- Prefer the axi wrappers over the raw CLIs when they exist: `gh-axi` for
  GitHub operations, `aws-axi` for AWS, `quota-axi` for agent-provider quota.
  They are token-efficient and suggest next steps.

## Etiquette

- Never stop the herdr server (`herdr server stop`) or kill its systemd unit —
  other agents run inside it.
- Don't run destructive or state-changing infrastructure commands (deploys,
  migrations, `terraform apply`) unless explicitly told to.
