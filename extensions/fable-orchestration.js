// Injects the fable-orchestration skill into the system prompt while the main
// session runs on a Claude Fable model. Subagents are skipped: the policy is
// for the orchestrating main loop, and a Fable subagent must not fan out.
//
// The skill body is read from disk on every prompt, so edits to SKILL.md
// apply from the next message without a restart. It is appended as the last
// system-prompt block, keeping the earlier blocks' prompt-cache prefix intact.
//
// SKILL.md is looked up next to this file first (<agent dir>/extensions/ →
// <agent dir>/skills/fable-orchestration/), then in ~/.omp/agent.
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SKILL = join("skills", "fable-orchestration", "SKILL.md");
const MARKER = "<fable-orchestration-policy>";

function skillPath() {
  const candidates = [join(homedir(), ".omp", "agent", SKILL)];
  try {
    candidates.unshift(join(dirname(fileURLToPath(import.meta.url)), "..", SKILL));
  } catch {}
  return candidates.find(p => existsSync(p));
}

function isFable(model) {
  if (!model || typeof model !== "object") return false;
  return /fable/i.test(`${model.id ?? ""} ${model.name ?? ""}`);
}

function currentModel(ctx) {
  try {
    return ctx?.models?.current?.() ?? ctx?.model;
  } catch {
    return ctx?.model;
  }
}

function skillBody() {
  const path = skillPath();
  if (!path) return null;
  return readFileSync(path, "utf8").replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "").trim();
}

export default function fableOrchestration(pi) {
  pi.on("before_agent_start", (event, ctx) => {
    if (event.reason === "revive") return;
    if (ctx.agent?.kind === "sub") return;
    if (!isFable(currentModel(ctx))) return;
    const base = Array.isArray(event.systemPrompt) ? event.systemPrompt : [String(event.systemPrompt ?? "")];
    if (base.some(block => block.includes(MARKER))) return;
    let body;
    try {
      body = skillBody();
    } catch {
      return;
    }
    if (!body) return;
    return {
      systemPrompt: [
        ...base,
        `${MARKER}\nYou are the Fable main loop. This delegation policy is active for the whole session (skill://fable-orchestration):\n\n${body}\n</fable-orchestration-policy>`,
      ],
    };
  });
}
