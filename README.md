# agent-dotfiles

Declarative environment for Debian cloud agent boxes (nix + standalone
home-manager). One command turns a fresh box into a ready agent workstation.

## Setup

```sh
curl -fsSL https://raw.githubusercontent.com/antonve/agent-dotfiles/main/bootstrap.sh | bash
```

Idempotent — re-run any time. It installs nix, clones this repo to
`~/xdev/personal/agent-dotfiles` (under `personal/` so the personal git
identity applies to it), activates the home-manager config, installs the
agent CLIs, and wires herdr up as a boot-persistent service.

## What you get

- **Agent harnesses**: `claude`, `codex`, `opencode`, `pi` — installed via
  their native installers/npm (they self-update; nixpkgs lags them), refresh
  with `agentbox-update`.
- **herdr** (from its nix flake) running as a systemd user service
  (`herdr server`) with lingering enabled, so it starts at boot and never dies
  with your SSH session. Connecting over SSH drops you straight into herdr;
  exiting/detaching herdr lands you in a normal shell. To skip the
  auto-attach: `touch ~/.no-herdr` on the box, or run a command instead of a
  login shell (`ssh box -- bash`) — plain `NO_HERDR=1 ssh` won't survive
  sshd's AcceptEnv filter. The herdr agent skill is installed for all
  harnesses so agents can talk across panes.
- **treehouse** (from its nix flake) for pooled git worktrees; the global
  AGENTS.md tells agents to start every task through it.
- **axi tools**: `gh-axi`, `aws-axi`, `quota-axi` with their skills and
  SessionStart hooks (deliberately no lavish-axi).
- **Dev tooling** from nixpkgs: git, gh, aws, gcloud, go, node, terraform,
  rg, fd, jq, fzf, make, htop, etc.
- **Familiar shell**: git aliases + settings (`files/gitconfig`, delta pager,
  rebase pulls, `push.autoSetupRemote`) and the dev-box-relevant subset of my
  zsh aliases, ported to bash (`g`, `x`, `l`/`la`, `tf`, `gcm`, …).
- **neovim** with `vim`/`vi` aliases, as `$EDITOR`.
- **Global agent instructions**: one `files/AGENTS.md` linked to
  `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md`
  and `~/.pi/agent/AGENTS.md`.
- `~/xdev` as the projects folder.
- **Secrets**: `~/.config/agentbox/secrets.env` (untracked, created from
  `secrets.env.example`, chmod 600). Exported into every interactive bash
  shell and the herdr server, so agents in panes pick up
  `OPENROUTER_API_KEY` and friends. After editing it, run
  `systemctl --user restart herdr` (when no agents are mid-task) so the
  server picks up the new values.

## Day-2 commands

| command | what it does |
|---|---|
| `add-ssh-key "ssh-ed25519 AAAA… you@host"` | grant SSH access (dedupes) |
| `agentbox-update` | refresh all agent CLIs, axi tools and skills |
| `home-manager switch --flake ~/xdev/personal/agent-dotfiles#agent-$(uname -m)-linux --impure -b backup` | apply config changes |
| `nix flake update` (then switch) | bump nixpkgs/herdr/treehouse pins |

Git identity lives in untracked files: edit
`~/.config/agentbox/git-identity` (default, work) and
`~/.config/agentbox/git-identity-personal` (used for repos under
`~/xdev/personal/**`). Bootstrap seeds both from `files/*.example`; commits
fail with "Please tell me who you are" until you fill in the default one.

## Testing

Never test against a live agent box; use the docker harness:

```sh
docker build -f test/Dockerfile .
```

It runs the full bootstrap on `debian:12` as a non-root sudo user and then
`test/verify.sh` asserts every tool, file, and service unit is in place.

## Notes

- `home.username`/`homeDirectory` resolve from the environment, hence
  `--impure` on every switch (boxes have per-engineer usernames).
- herdr persistence: the systemd **user** service plus
  `loginctl enable-linger` binds the server to the machine, not to a login
  session. Don't run `herdr server stop` on a box with agents working.
