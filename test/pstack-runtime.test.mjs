import assert from "node:assert/strict";
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const plugin = path.join(repo, "plugins/pstack-agentbox");
const stateModule = await import(path.join(plugin, "hooks/scripts/poteto-mode-state.mjs"));
const setupModule = await import(path.join(plugin, "skills/setup-pstack/scripts/manage-agents.mjs"));

test("Poteto mode activates only from an explicit supported invocation", () => {
  assert.equal(stateModule.classifyPrompt("$poteto-mode build it"), "activate");
  assert.equal(stateModule.classifyPrompt("$pstack-agentbox:poteto-mode build it"), "activate");
  assert.equal(stateModule.classifyPrompt("please use $poteto-mode"), "inactive");
  assert.equal(stateModule.classifyPrompt("disable $poteto-mode"), "disable");
  assert.equal(stateModule.classifyPrompt("$pstack-for-codex:poteto-mode"), "inactive");
});

test("Poteto mode state is session-scoped and can be disabled", async (t) => {
  const pluginData = await fs.mkdtemp(path.join(os.tmpdir(), "pstack-agentbox-hook-"));
  t.after(() => fs.rm(pluginData, { recursive: true, force: true }));
  const input = {
    hook_event_name: "UserPromptSubmit",
    session_id: "session-a",
    cwd: repo,
    prompt: "$pstack-agentbox:poteto-mode build it",
  };

  const activated = await stateModule.handleHook(input, { pluginData, now: 1_000 });
  assert.match(activated.hookSpecificOutput.additionalContext, /sticky receipt/);

  const continued = await stateModule.handleHook(
    { ...input, prompt: "continue" },
    { pluginData, now: 2_000 },
  );
  assert.match(continued.hookSpecificOutput.additionalContext, /active for this session/);
  assert.equal(
    await stateModule.handleHook(
      { ...input, session_id: "session-b", prompt: "continue" },
      { pluginData, now: 2_000 },
    ),
    null,
  );

  await stateModule.handleHook(
    { ...input, prompt: "disable $poteto-mode" },
    { pluginData, now: 3_000 },
  );
  assert.equal(
    await stateModule.handleHook({ ...input, prompt: "continue" }, { pluginData, now: 4_000 }),
    null,
  );
});

test("setup-pstack owns and reverses only its receipted profiles", async (t) => {
  const temporary = await fs.mkdtemp(path.join(os.tmpdir(), "pstack-agentbox-setup-"));
  t.after(() => fs.rm(temporary, { recursive: true, force: true }));
  const projectRoot = path.join(temporary, "project");
  const userHome = path.join(temporary, "home");
  await fs.mkdir(projectRoot, { recursive: true });
  await fs.mkdir(userHome, { recursive: true });

  const installed = await setupModule.installAgents({ pluginRoot: plugin, projectRoot, userHome });
  assert.equal(installed.status, "installed");
  assert.equal(installed.files.length, 2);
  assert.match(installed.receiptPath, /pstack-agentbox-agent-receipt\.json$/);

  const receipt = JSON.parse(
    await fs.readFile(path.join(projectRoot, installed.receiptPath), "utf8"),
  );
  assert.equal(receipt.owner, "pstack-agentbox/setup-pstack");

  const removed = await setupModule.uninstallAgents({ projectRoot, userHome });
  assert.equal(removed.status, "uninstalled");
  for (const file of installed.files) {
    await assert.rejects(fs.stat(path.join(projectRoot, file.path)), { code: "ENOENT" });
  }
});
