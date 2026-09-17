# Upstream provenance

`pstack-agentbox` is an owned Agent Box derivative of two MIT-licensed sources:

- Lauren Tan's `pstack` in `cursor/plugins`, version 0.15.1 at commit `f8abeddd1862dc73704e3d719dd73df0d51b8c71`.
- `Aqua-123/pstack-for-codex` at commit `2bea6dca0da10e81d6579ec7e45d9ab1ece948c8`, used as the reviewed Codex porting reference.

The bundled `LICENSE` and `NOTICE` preserve upstream attribution. This derivative keeps the Codex-native explicit skill and runtime contracts while applying Agent Box-specific changes:

- omit `bro`, `make-bot-ui`, `setup-benny`, and the Benny automation pack;
- remove Graphite-only playbooks and helpers;
- use Draft for multi-phase plan review;
- allow active pstack workflows to select PR readiness and an authorized GitHub interface;
- keep ordinary Agent Box behavior unchanged when pstack is inactive.

Review newer upstream versions in a temporary checkout. Third-party repositories remain read-only. Port selected changes into this directory, update both pinned commits above, and rerun the plugin, skill, runtime, and repository verification suites.
