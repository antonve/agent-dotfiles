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

## Scope discipline

- Keep changes strictly within the requested scope. Never broaden a task in the
  name of "safety," completeness, hardening, or general best practice.
- For a bug fix or targeted change, make the smallest coherent change that
  addresses the core issue. Avoid unrelated cleanup, refactors, abstractions,
  compatibility layers, or defensive code.
- Verification must be purposeful and proportional to the change. Do not add
  speculative smoke tests, CI jobs, shell-script tests, or other test
  infrastructure merely because code was touched. Add tests only when they
  provide focused evidence for the requested behavior.
- Treat broader refactors and larger test strategies as separate design work:
  state their purpose and get agreement before implementing them. Prefer small,
  reviewable increments; large batches of code are difficult to verify reliably.

## Planning

- Treat planning as an interactive design process, not a one-shot document.
  Prefer short back-and-forth exchanges: ask frequent focused questions,
  investigate plausible approaches, and compare their tradeoffs before settling
  on a direction.
- When a plan is finalized, persist it as Markdown under `~/xdev/plans`, the
  canonical location for all plans. Update the existing plan as decisions,
  scope, or implementation status change instead of letting it become stale.
- Split each plan into explicit phases. Represent every actionable step in each
  phase as a Markdown checkbox (`- [ ]`), and change it to `- [x]` when the step
  is completed so the plan always shows current progress.

## Etiquette

- GitHub writes are allowed only in repositories owned by the account currently
  authenticated in `gh`. Never create PRs, issues, comments, reviews, releases,
  pushes, or other mutations in external repositories, even when asked to
  contribute upstream, unless the user first changes this machine's declarative
  guardrail policy themselves. Never bypass the guard with raw HTTP/API calls,
  alternate binaries, `--no-verify`, disabled hooks, or direct credentials.
- Prefix every agent-authored GitHub comment, review, or reply with a bold
  `**Reply by <model name>**` header, using the active model's name.
- When checking code-review comments, reply on GitHub to every relevant review
  thread with the outcome (addressed, declined with rationale, or clarification
  requested). Do not process review feedback only locally; keep the back and
  forth recorded on GitHub.
- Write PR descriptions as concise decision aids for human reviewers, not
  exhaustive change logs. Include only the reason for the change, what changed,
  what reviewers should focus on, material risks, and the rollout/rollback plan.
  Make the expected reviewer action obvious at first glance; omit routine detail
  that does not affect the review or decision.
- NEVER put AI/tooling metadata in commit messages or PR descriptions: no
  session links, no `Co-Authored-By`, no "Generated with ..." lines. Commit
  messages describe the change, nothing else.
- Do not amend existing commits or force-push branches by default. Only perform
  either operation when the user explicitly requests that specific operation.
- Never stop the herdr server (`herdr server stop`) or kill its systemd unit —
  other agents run inside it.
- Don't run destructive or state-changing infrastructure commands (deploys,
  migrations, `terraform apply`) unless explicitly told to.
