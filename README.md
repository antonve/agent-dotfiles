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
- **axi tools**: `gh-axi` and `quota-axi` with their skills and `gh-axi`
  SessionStart hooks (deliberately no lavish-axi).
- **Dev tooling** from nixpkgs: git, gh, aws, gcloud, node, terraform, rg, fd,
  jq, fzf, make, htop, and a common Go toolset (`gopls`, `golangci-lint`,
  `dlv`, `gofumpt`, `goimports`, `staticcheck`, and `govulncheck`).
- **Familiar shell**: git aliases + settings (`files/gitconfig`, delta pager,
  rebase pulls, `push.autoSetupRemote`) and the dev-box-relevant subset of my
  zsh aliases, ported to bash (`g`, `x`, `l`/`la`, `tf`, `gcm`, …).
- **neovim** with `vim`/`vi` aliases, as `$EDITOR`.
- **Draft standalone** as a boot-persistent Docker Compose application, with
  daily backup-first image updates and its CLI installed at `~/.local/bin/draft`.
  It has no application authentication and both ports bind to loopback only;
  the SSH helper forwards the web UI to `http://127.0.0.1:8765`.
- **Global agent instructions**: one `files/AGENTS.md` linked to
  `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md`
  and `~/.pi/agent/AGENTS.md`. The vendored user-invoked `bro` skill is also
  available in every harness for restating the last response without jargon.
- **Managed Pi package**: selectable GitHub Dark or Gruvbox Dark UI, `ask_user`, `/copy-all`, calm
  collapsed tool output, structured system `fd`/`rg`, Git/model dashboard
  state, Linear read/write tools, per-run summaries, and visible Herdr orchestration for background
  commands, Pi/Claude/Codex/OpenCode
  children, and workflows. Mutation-capable delegation uses guarded Treehouse
  leases. Firecrawl is intentionally excluded. Pi loads the mutable
  `~/xdev/personal/pi-agent` checkout directly; every Pi launch, Home Manager
  activation, and `agentbox-update` attempts to fast-forward it to the latest
  `origin/main`.
- `~/xdev` as the projects folder.
- **Secrets**: `~/.config/agentbox/secrets.env` (untracked, created from
  `secrets.env.example`, chmod 600). Exported into every interactive bash
  shell and the herdr server, so agents in panes pick up
  `OPENROUTER_API_KEY`, `LINEAR_API_KEY`, and friends. After editing it, run
  `systemctl --user restart herdr` (when no agents are mid-task) so the
  server picks up the new values.

## Logging in to codex / opencode (browser OAuth)

Device-code login is disabled, and both `codex login` and
`opencode auth login` receive their OAuth callback on `localhost:1455`
*inside the VM* — which your browser can't reach. Connect with the callback
port forwarded instead:

```sh
./gcloud-ssh-box.sh    # IAP SSH + OAuth and Draft localhost forwards
```

The script labels the terminal tab `REMOTE - agent box` for the duration of
the connection and restores its previous title on exit. Then run `codex login`
(or `opencode auth login`) on the box, open the printed URL in your local
browser, and the `localhost:1455` redirect gets forwarded through the SSH
session into the CLI. Log in to one CLI at a time (they contend for the same
port). The box coordinates live in
`~/.config/agentbox/box.env` on the machine you connect from (untracked;
copy `files/box.env.example`).

## Day-2 commands

| command | what it does |
|---|---|
| `add-ssh-key "ssh-ed25519 AAAA… you@host"` | grant SSH access (dedupes) |
| `agentbox-update` | refresh all agent CLIs, the local `pi-agent` checkout, axi tools and skills |
| `agentbox-disk-reclaim` | reclaim safe disposable data when `/` is above 80% usage |
| `draft-standalone status` | show the Draft Compose services and health |
| `draft-standalone update` | pull a matching API/web pair, back up PostgreSQL, migrate, and restart |
| `draft-standalone backup` | create a retained PostgreSQL dump without updating |
| `draft-standalone logs [service]` | follow Draft Compose logs |
| `pi-agent-update` | fast-forward `~/xdev/personal/pi-agent` to the latest `origin/main` immediately |
| `pi-theme [github-dark-default\|gruvbox-dark]` | select this computer's Pi theme and update current settings; existing sessions need `/reload` |
| `home-manager switch --flake ~/xdev/personal/agent-dotfiles#agent-$(uname -m)-linux --impure -b backup` | apply config changes |
| `nix flake update` (then switch) | bump nixpkgs/herdr/treehouse pins |
| `systemctl --user status pi-herdr-janitor.timer` | inspect durable Herdr/Treehouse cleanup |
| `journalctl --user -u pi-herdr-janitor.service` | inspect orphan/dirty-lease cleanup diagnostics |
| `systemctl --user status agentbox-disk-reclaim.timer` | inspect the hourly disk-usage check |
| `journalctl --user -u agentbox-disk-reclaim.service` | inspect disk cleanup decisions and results |
| `systemctl status draft-standalone.service` | inspect the boot-persistent Draft stack |
| `systemctl status draft-standalone-update.timer` | inspect the persistent daily update timer |

Draft keeps PostgreSQL in a named Docker volume and stores 14 days of database
dumps under `~/.local/state/draft-standalone/backups`. The updater refuses to
deploy when the public API and web image revision labels disagree. It never
automatically rolls back a database migration.

The hourly disk guard does nothing while the root filesystem is at or below
80% usage. Above that threshold it first prunes only unreferenced Docker build
cache and images, dangling package cache entries, unreachable Nix store paths,
and Treehouse worktrees that are clean, merged, idle, and unleased. If usage
remains above 80%, it clears rebuildable npm, uv, Bun, and Go caches. It never
removes Docker containers or volumes, project files, reachable Nix paths, or
active, dirty, unmerged, or leased Treehouse worktrees. Cleanup runs with idle
I/O priority and continues past unavailable tools or individual failures.

Git identity lives in untracked files: edit
`~/.config/agentbox/git-identity` (default, work) and
`~/.config/agentbox/git-identity-personal` (used for repos under
`~/xdev/personal/**`). Bootstrap seeds both from `files/*.example`; commits
fail with "Please tell me who you are" until you fill in the default one.

GitHub writes are limited to the account currently authenticated in `gh` plus
owners listed in the installation-local
`~/.config/agentbox/github-write-owners`. Add one trusted work organization or
user login per line; blank lines and `#` comments are ignored. Bootstrap and
Home Manager seed an empty 0600 file from
`files/github-write-owners.example`. Reads from other owners remain available.

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
