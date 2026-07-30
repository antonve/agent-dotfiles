---
name: pi-setup-development
description: Develop or review the Pi extension package under files/pi in this agent-dotfiles repository. Use only when changing this repository's Pi extensions, Pi skills, Pi theme, Pi package integration, or their tests.
---

# Pi setup development

This setup targets Pi 0.83 and is deployed declaratively through Home Manager.

1. Read [references/typescript-conventions.md](references/typescript-conventions.md) before editing TypeScript.
2. Never edit Herdr-generated integration files, especially `~/.pi/agent/extensions/herdr-agent-state.ts`.
3. Keep mutable state under `~/.local/state/pi-herdr` or `~/.config/pi-herdr`, never under the managed package.
4. Run `npm run format:check`, `npm run check`, and `npm test` from `files/pi`.
5. Evaluate Home Manager after integration changes.
