### Multi-phase or multi-PR plan

**Own the plan, not the implementation.** Use when work spans phases, multiple PRs, or a later operator review. The plan is the deliverable until the operator approves execution.

1. Skip a separate plan when the change is one or two files with an obvious approach. Say why.
2. Settle observable technical questions with read-only investigation or a throwaway prototype. Ask the operator only for product or preference choices that evidence cannot decide.
3. Inspect repository instructions, entry points, conventions, and verification commands. Use isolated delegates only when the runtime contract permits them.
4. Create a self-contained HTML or Markdown source with the checklist below. Local files are temporary publishing inputs, never a second canonical plan store.
5. Apply `$technical-writing` and `$unslop`.
6. Invoke `$draft-review-workflow`. Publish with a stable slug and retain the returned pinned URL and version.
7. Ask the operator to submit Draft review feedback. Wait through the workflow's bounded feedback command. Apply every comment against the reviewed version, republish from that exact base, and resolve the review only after the requested implementation succeeds.
8. Stop after returning the pinned reviewed plan. Implementation begins only when the operator approves execution or the submitted review clearly approves the plan subject only to comments you applied.

The plan must use `- [ ]` for work and `- [x]` only for evidence-backed completion. Keep phases, progress, and decisions current in Draft as execution proceeds.

```markdown
# <Outcome> plan

<Who benefits, what changes, and the ordered delivery units.>

## Decisions

- <Settled choice and evidence.>

## Phase 1. <Observable milestone>

- [ ] <One scoped change.>
- [ ] Verify with `<command or live procedure>`.

## Phase 2. <Observable milestone>

- [ ] <One scoped change.>
- [ ] Verify with `<command or live procedure>`.

## Delivery

- [ ] Record each branch, PR, base, and dependency.
- [ ] Apply the active repository and workflow rules for GitHub tooling and PR readiness.
- [ ] Stop at any merge, deploy, or external-write gate not already authorized.

## Acceptance criteria

- [ ] <User-visible result.>
- [ ] <Maintainer-visible invariant.>

## Risks and exclusions

- <Risk, mitigation, and explicit non-goal.>
```

Verification must match risk. Use unit checks for local logic, integration or live checks for boundaries, and performance measurements only when performance is part of the claim. Do not require a fixed lane count or ceremonial evidence that cannot change the verdict.

**Reply:** provide the pinned Draft URL, delivery-unit dependencies, decisions supported by evidence, unresolved product choices, and the requested next action.
