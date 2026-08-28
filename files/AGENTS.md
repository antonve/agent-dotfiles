# Agent Box

This machine is a Debian cloud agent box managed by
[agent-dotfiles](https://github.com/antonve/agent-dotfiles). The home
environment is declarative (nix + home-manager) — don't hand-edit managed
dotfiles; change the repo in `~/xdev/personal/agent-dotfiles` and run
`home-manager switch --flake ~/xdev/personal/agent-dotfiles#agent-$(uname -m)-linux --impure -b backup`.

## Upstream repositories are read-only

Classify repository ownership before investigation, planning, delegation,
Treehouse acquisition, implementation, review, or other token-intensive work.
Third-party upstream public open-source repositories used by this setup are
strictly read-only. This includes upstream Herdr (`ogulcancelik/herdr`) and the
upstream Pi coding-agent package and repository. Reading their documentation or
source for diagnosis is allowed.

If a requested or proposed change targets such an upstream, stop immediately.
Never edit its source, create local commits, patches, or branches, push, open
pull requests, assign implementation tasks against it, or change its releases
or runtime to solve a local integration problem. Do not investigate
implementation options there, spawn agents, create plans or patches, or ask
whether to contribute upstream. Report the immutable boundary concisely and
redirect only to an owned integration, configuration, or product repository
when one can solve the problem; otherwise report the upstream limitation.

Public visibility alone does not make a repository upstream. Repositories owned
by this setup, such as `antonve/pi-agent`, `antonve/agent-dotfiles`, and product
repositories, remain valid change targets subject to the GitHub owner policy.

## Mate orchestration hierarchy

- **First mate:** Pure orchestration and captain communication. It never performs task research, implementation, or repository work. It assigns every task, ticket, or project to exactly one persistent second mate and remains available to the captain.
- **Second mate:** Owns scope and end-to-end delivery for exactly one assigned task and must not drift beyond it. It is the task's scope gate and quality owner: it keeps every worker and change within the assigned scope, decomposes work into small coherent units, directly creates and manages suitable subagents as leaf workers, and parallelizes independent units where appropriate. It monitors their work, reviews and verifies their outputs, and rejects, re-scopes within the task, or splits work that becomes too large to review or use safely. It never writes implementation code or performs other executable work itself. It bubbles captain-level decisions and feedback to the first mate.
- **Leaf workers:** Subagents are the executable leaf workers or nodes. Each performs only its bounded assignment using the suitable harness and model, reports results to the second mate, and does not create subagents of its own.
- **Communication chain:** Escalations move `leaf workers -> second mate -> first mate -> captain`; decisions and feedback return down the same chain. Do not bypass levels.
- **Workflow completion:** Completing a worker, second-mate, or agent assignment is not equivalent to completing its Linear ticket, project, or deliverable. Never transition a Linear issue to Done or Completed, move it to the end of a project, or otherwise infer workflow completion merely because agent work finished. That specific issue and transition require explicit captain authorization. Keep the issue open while human review, publication, rollout, acceptance, or other deliverable steps remain outstanding.

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
- When beginning work on a Linear issue in Herdr, rename the current tab as soon
  as the issue identifier and title are known:
  `herdr tab rename "$HERDR_TAB_ID" "<ISSUE-ID>-<short-topic>"`. Use the exact
  uppercase issue identifier followed by one to three lowercase title keywords
  in kebab-case. Keep the label short, rename it again when switching the tab to
  a different issue, and never rename another tab. Never apply this to mate
  tabs: a session with `PI_FIRST_MATE_ROLE=second-mate` must keep its tab
  exactly `secondmate`, and the first-mate session must keep its tab exactly
  `firstmate`. Linear identifiers still belong in linked task workspace names,
  not mate tab labels.
- Installed harnesses: `claude`, `codex`, `opencode`, `pi`.
- Ports `8766`–`8784` are reserved and approved for agents running localhost-only local development servers, HTML report servers, previews, and similar temporary services. Bind only to `127.0.0.1` or `localhost`, choose an available port within that range, and avoid conflicts with active services.
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
- Prefer `gh-axi` for GitHub operations and `quota-axi` for agent-provider
  quota; they are token-efficient and suggest next steps.
- For AWS operations, use the standard `aws` CLI and require an explicit
  `--profile <name>` and `--region <region>` on every command.

## Scope discipline

- Keep changes strictly within the requested scope. Never broaden a task in the
  name of "safety," completeness, hardening, or general best practice.
- For a bug fix or targeted change, make the smallest coherent change that
  addresses the core issue. Avoid unrelated cleanup, refactors, abstractions,
  compatibility layers, or defensive code.
- Do not leave task-specific phase labels, issue IDs, rollout chronology, or
  implementation-history breadcrumbs in code comments or durable repository
  documentation. Explain the enduring behavior or constraint instead; keep
  transient execution tracking in the plan, issue, or pull request.
- Verification must be purposeful and proportional to the change. Do not add
  speculative smoke tests, CI jobs, shell-script tests, or other test
  infrastructure merely because code was touched. Add tests only when they
  provide focused evidence for the requested behavior.
- Treat broader refactors and larger test strategies as separate design work:
  state their purpose and get agreement before implementing them. Prefer small,
  reviewable increments; large batches of code are difficult to verify reliably.

## Reuse-first design

- Before designing or implementing, find the closest existing implementation in
  the same repository or project and in any relevant owned sibling project that
  project documentation points to. Treat established structure, naming,
  workflow, testing approach, and operational model as the default constraint;
  explicit instructions to follow an existing pattern are mandatory.
- Prefer copying or minimally adapting that implementation, changing only the
  inputs or behavior the task requires. Never invent a new abstraction, CI flow,
  test harness, safety mechanism, architecture, or parallel convention merely
  because it seems cleaner or more robust.
- If a material deviation appears necessary, stop before implementation. Present
  the existing pattern, proposed difference, concrete reason direct reuse cannot
  work, maintenance cost and tradeoffs, and smallest alternatives, then obtain
  explicit user approval.
- If no applicable pattern exists, say so and discuss the design before
  implementation rather than silently treating the task as greenfield.

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

- Do not mention or tag people, request reviews, assign work, or take any other
  action that is likely to notify someone or solicit human attention unless the
  user explicitly authorizes that specific action.
- GitHub writes are allowed only in repositories owned by the account currently
  authenticated in `gh` or an owner listed in the installation-local
  `~/.config/agentbox/github-write-owners` allowlist. Never add owners to that
  file or create PRs, issues, comments, reviews, releases, pushes, or other
  mutations elsewhere unless the user explicitly requests the policy change.
  Never bypass the guard with raw HTTP/API calls, alternate binaries,
  `--no-verify`, disabled hooks, or direct credentials.
- In every user-facing status update, progress report, completion report,
  summary, handoff, or similar message, include a directly usable full URL for
  each referenced pull request, even when its number or title is also present;
  never leave a PR reference vague or unlinked.
- Determine pull-request draft policy from the actual GitHub repository owner,
  never its local path or public/private visibility. For every owner other than
  exactly `antonve`, create new PRs as drafts and never mark them ready for
  review; only the user or a human repository owner does that after confirming
  quality. This remains true when implementation, tests, and agent reviews are
  complete and when the user merely says to open a PR; only an explicit draft-
  status override for that specific PR permits a review-ready PR. Preserve
  draft status when updating existing PRs, and do not request or tag reviewers
  or otherwise solicit review. Repositories owned by `antonve` are exempt and
  retain the existing review-ready convention unless the user requests a draft.
- Bypass repository rules only with explicit user authorization for that merge.
  Never enable auto-merge or bypass with failing configured checks.
- For an authorized bypass merge, run
  `npx -y gh-axi pr checks <PR> --repo=<owner/repo>` and require every configured
  check to be green. Inspect the PR's full head SHA and the repository's allowed
  merge methods, then attempt the focused admin path with an allowed method, for
  example: `npx -y gh-axi pr merge <PR> --repo=<owner/repo> --squash --admin`.
  If focused tooling cannot bypass the rule, use the permitted authenticated
  fallback with the exact full head SHA and an allowed method, for example:
  `npx -y gh-axi api PUT /repos/<owner>/<repo>/pulls/<PR>/merge --field sha=<FULL_HEAD_SHA> --field merge_method=squash`.
  Never use a stale head SHA, raw `gh`, `curl`, or direct credentials. If the head
  changes, repeat checks and inspection. Verify the merged result and resulting
  SHA before reporting success.
- Prefix every agent-authored GitHub comment, review, or reply with a bold
  `**Reply by <model name>**` header, using the active model's name.
- When the user asks to handle review comments, ignore automated review-bot
  comments by default. Only act on comments from antonve, plus any other
  reviewers the user names explicitly. For those comments, reply on GitHub to
  every relevant review thread with the outcome (addressed, declined with
  rationale, or clarification requested). Do not process review feedback only
  locally; keep the back and forth recorded on GitHub.
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
