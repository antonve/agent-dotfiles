# Agent Box

This Debian agent box is managed declaratively by `~/xdev/personal/agent-dotfiles`
using Nix and Home Manager. Change the repository, never managed home files;
see its README for setup and activation commands.

## Environment

- Projects live in `~/xdev`; personal repositories belong in `~/xdev/personal`.
- Secrets belong in untracked `~/.config/agentbox/secrets.env`. Never print or
  commit secrets or hardcode machine/organization-specific configuration.
- Bind temporary previews to loopback on an available port in `8766`–`8783`.
  Port `8784` is reserved for T3 Code. Do not stop shared services.
- Prefer `gh-axi` for GitHub and `quota-axi` for provider usage; use their skills
  for operational details.

## Scope and ownership

- Classify ownership before repository work. Third-party upstream repositories
  are read-only: documentation/source inspection for diagnosis is allowed, but
  never plan or implement changes, create patches/branches, delegate changes,
  or mutate upstream releases/runtime to solve local integration problems.
  Stop at that boundary and use an owned integration repository when possible.
  Public visibility alone does not make an owned repository upstream.
- Keep changes within the requested scope, reuse existing project patterns,
  and make the smallest coherent change with proportional verification.
  Discuss material design deviations before implementation.
- Keep transient task history and issue IDs out of durable code/documentation.

## Planning and review

- Use planning as an interactive design process: discuss meaningful choices
  with the user before finalizing the plan.
- Planning documents are mandatory and live in Draft as the canonical source.
  Split plans into phases, use `- [ ]` for actionable steps and `- [x]` for
  completed steps, and keep progress and decisions current as work proceeds.
- Use the `draft-review-workflow` skill to publish plans and share pinned review
  URLs. Local files are temporary editing/publish inputs, not a second plan store.
  Process submitted feedback and update from the exact base revision.
- Do not mark a Linear issue Done/Completed or move it to the end of a project
  merely because agent work finished; that specific transition requires explicit
  user authorization.

## GitHub and consequential actions

- Prefix every model-authored GitHub reply with this header, substituting the
  model's name for `$modelName`:
  ```md
  > [!NOTE]
  > 🤖 **$modelName responding on behalf of Anton**
  ```
- Commit completed task changes automatically and push to that task’s existing PR.
  If no PR exists, push the task branch and open a draft PR automatically once
  the work is ready for review and appropriate verification is complete. Do not
  ask for permission to create the draft PR unless the user has instructed otherwise.
- Format every pull request reference as a Markdown link so it is clickable.
- GitHub writes are allowed only for the authenticated account or owners in
  `~/.config/agentbox/github-write-owners`. Never change that allowlist or bypass
  guards without an explicit user request to change the policy.
- Create PRs as drafts for every owner and preserve draft status. Only an explicit
  override for that PR permits marking it ready.
- Do not notify/tag people, request reviews, or solicit attention without explicit
  authorization for that action.
- Bypass repository rules only with explicit authorization for that merge, all
  configured checks green, and the verified current head SHA and allowed method.
  Never enable auto-merge or bypass with failing checks; verify the merged result.
- Do not amend existing commits or force-push branches by default; each requires
  explicit authorization. Keep commit messages and PR descriptions free of AI
  attribution, session links and `Co-Authored-By` trailers.
- Deploys, migrations and other destructive or state-changing infrastructure
  commands require explicit authorization.
