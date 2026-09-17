Delegation, lifecycle, isolation, history, and capability fallbacks follow `../references/codex-agent-runtime.md`.

### Opening a PR

Invoked at the end of another playbook when the request and repository policy authorize a pull request.

**Isolation.** Work from a clean task branch or isolated worktree. Preserve unrelated user changes. Do not rewrite published history without explicit authorization.

**Commits.** Keep commits coherent and ordered. Use a new commit for a separable correction. Amend or force-push only when explicitly authorized.

**PR writing.** Apply `$technical-writing` and `$unslop` to the title and description. Apply `$deslop` and `$no-comments` to the diff when those skills are installed.

Use a short imperative title that follows repository conventions. Use only the description sections that carry information:

- `## Why`
- `## Scope`
- `## Tradeoffs`
- `## Blast Radius`
- `## Verification`

State observed outcomes, not only commands. Attach screenshots or recordings when they prove a user-visible claim.

**Mechanics.** Use an available GitHub interface that is authorized for the repository. Choose draft or ready status from the task state and active workflow rather than imposing one globally. Prefer independent PRs from the repository's normal base. For dependent changes, preserve and report the explicit base relationship without requiring a stack manager.

Opening a PR does not start Babysit. Return the clickable PR URL and continue only when the active playbook requires more work.

**Reply:** provide the PR link, status, head SHA, base, verification performed, and any remaining gate.
