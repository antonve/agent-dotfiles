Delegation, lifecycle, isolation, history, and capability fallbacks follow `../references/codex-agent-runtime.md`.

### Orchestrate

**Own the program, not every implementation.** Use this playbook for a multi-day project with many independent or dependency-ordered units and a standing coordinator. A single task that fits in one session routes to Autonomous run. A one-off complex run routes to figure-it-out.

Open a todolist with the steps below copied in order. Keep skipped steps with a one-line reason.

#### Roles

- The coordinator frames the program, writes briefs, drains completions, maintains durable state, and integrates only when authorized.
- A worker owns one isolated worktree, branch, or output directory. It returns evidence rather than a claim of completion.
- A verifier is independent from the worker when verification needs judgment, a live surface, or high-blast-radius review.
- Add a sub-coordinator only when one coordinator cannot drain the active worker set. Keep nesting to coordinator, track, worker.

#### Durable state

Create `orchestrate/<project-slug>/` beneath an operator-provided state root. Do not infer a private host path. Keep the format plain and inspectable.

- `preferences.md` contains numbered standing orders.
- `units.tsv` records unit, track, state, branch, PR, head SHA, and brief path.
- `ledger.tsv` records verification verdicts keyed by PR and head SHA.
- `inbox/` contains completion pointers.
- `gates.md` contains questions that require the operator.
- `decisions.tsv` is the trail maintained through show-me-your-work.
- `status.md` is regenerated from the tables at each drain.

Give each file one writer. Write updates atomically. A new head SHA invalidates the matching verification row.

#### Brief

Every dispatch includes the following fields. Collapse the format for tiny units, but do not omit the information.

```text
GOAL         one observable outcome
SCOPE        allowed paths and exclusive worktree, branch, or output directory
CONTEXT      file, issue, PR, and upstream-result pointers needed without chat history
ACCEPTANCE   checkable criteria
VERIFY       exact commands or control-skill procedure
TIMEBOX      bounded runtime and partial-result behavior
FORBIDDEN    no force-push, no unrelated fixes, plus unit-specific bans
REPORT       status, branch, SHA, PR, evidence, deviations, follow-ups
STANDING     current preferences.md content or a resolvable pointer
```

Missing scope, acceptance, isolation, or verification is a refuse-to-dispatch condition.

#### Steps

1. **Frame.** State a countable done predicate, unit count, tracks, dependency order, in-flight limit, verification bar, and wall-clock budget. Route smaller work to Autonomous run.
2. **Prepare.** Create the durable state, open the show-me-your-work trail, record standing orders, and inventory existing branches and PRs through an available repository interface.
3. **Pilot.** Run one representative unit through brief, implementation, verification, PR delivery, and authorized integration. Correct the brief and unit size from evidence.
4. **Scale.** Keep a rolling window of isolated workers. Start a dependent unit only when its inputs are stable. Relay upstream results into the next brief.
5. **Drain.** Batch completion processing. Classify each result, update `units.tsv` and `ledger.tsv`, record gates, regenerate `status.md`, and refill the window.
6. **Integrate.** Deliver verified work continuously through the repository's available branch and PR mechanisms. Preserve explicit authority for pushes, merges, deployments, and external messages.
7. **Close.** Reconcile every worker to a terminal state, verify the real done predicate, audit the decision trail, and leave the durable state intact.

#### Queue discipline

- A completion is an inbox event. Do not abandon the current critical section to review it inline.
- Drain after a critical section, at a track rollup, at an authorized monitoring tick, and before a human report.
- Account for every worker as completed, replaced, abandoned, or absorbed into another unit.
- Retry a resource failure with smaller scope, a network failure once as-is, and an unknown failure once. Replan after the bounded retry.
- After a restart, treat worker liveness as unknown and reconcile by branch, commit, PR, durable files, and supported task state before replacing work.

#### Verification

Cheap deterministic checks stay with the worker and are spot-checked. Expensive, judgment-heavy, live, or high-risk checks get an independent verifier. CI is evidence, not the whole verdict. Record the exact head SHA and observable result in `ledger.tsv`.

#### Escalation

Batch genuine product decisions, irreversible actions, conflicting standing orders, and program-level dead ends in `gates.md`. Do not escalate routine retries, status checks, formatting fixes, or work already excluded by the brief.

**Reply:** report the done predicate and current count, track status, delivered PR links and head SHAs, verification verdicts, abandoned work, open gates, and durable state path.
