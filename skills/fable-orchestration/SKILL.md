---
name: fable-orchestration
description: "Delegation policy for a Claude agent stack where the main loop runs on a strong but expensive model (Claude Fable 5.2). The main loop orchestrates, writes briefs and synthesizes; the work is routed by difficulty. Medium-high difficulty goes to Opus with a fairly loose brief; second opinions and out-of-the-box thinking go to a fresh Opus with a peer-style brief. Simple-medium goes to Sonnet with a tighter brief; precise execution of an already-decided plan goes to Sonnet with a detailed step-by-step brief. Very large data cleanup goes to Claude Haiku 5.5, or Sonnet when the rules need care. Auto-injected while the main session runs on Fable; load whenever spawning subagents (task tool, eval agent()/workpool()) or planning any delegation."
---

# Orchestration & delegation policy (expensive-main-loop stack)

A routing policy for stacks with **one strong, expensive main-loop model** and
**cheaper delegate tiers**. Written against a Claude Fable 5.2 main loop with
Opus, Sonnet and Haiku subagents, but the shape transfers to any stack with
the same economics.

Core law: **the expensive model's tokens buy judgment, not throughput.** It
writes the plan, the briefs, the hard calls and the final synthesis.
Everything else goes to the cheapest tier that can carry it.

## The routing table

| Work | Goes to | `model` value | Brief style |
|---|---|---|---|
| Architecture, specs, hard judgment, integration, final synthesis | **Main loop** (Fable) | itself | n/a |
| Medium-high difficulty: multi-file implementation, real debugging, research that needs judgment, review and verification | **Opus** | `anthropic/claude-opus-5-5:high` | Fairly loose: goal, context, constraints, what done looks like |
| Second opinion, out-of-the-box thinking, an angle the main loop may be missing | **Opus** (fresh instance, not the one that did the work) | `anthropic/claude-opus-5-5:high` | The open question plus the evidence, as to a peer |
| Simple-medium: scoped edits, pattern clones, lookups, templated work, straightforward reading and summarizing | **Sonnet** | `anthropic/claude-sonnet-5-5:medium` | A notch tighter: named files, steps, output shape, boundaries |
| Precise execution of an already-decided plan, step by step | **Sonnet** | `anthropic/claude-sonnet-5-5:medium` | Detailed and step by step, nothing left implicit |
| Very large data cleanup: thousands of rows or files, normalizing, deduplicating, classifying, extracting | **Claude Haiku 5.5** (or **Sonnet** when the rules need care) | `anthropic/claude-haiku-5-5:high` / `anthropic/claude-sonnet-5-5:medium` | Exact rule set with input and output examples, small batches, spot checks |

## The hard rules

1. **Always pass an explicit `model`** on every `task` tool `tasks[]` item and
   every eval `agent()` / `workpool()` call. Omitting it falls back to the
   default agent model and silently fans out a tier you did not choose.
2. **The main-loop model is not a subagent tier.** Spawn Fable as a subagent
   only when the operator names it for that task, or when a rare
   judgment-heavy piece genuinely fails on Opus.
3. **Route by difficulty, then pick the cheapest tier that can carry it.**
   When unsure between two tiers, take the cheaper one and verify the result;
   escalate one tier on failure rather than starting high.
4. **Second opinions come from a fresh context.** A hard call is reviewed by a
   new Opus instance that has not seen the main loop's reasoning or the
   delegate's work, so it cannot simply agree with it. Bulk cleanup defaults to
   Haiku; move it to Sonnet only when Haiku's spot checks fail.
5. **The main loop keeps its own context lean.** Wide reading, file dumps and
   raw data go to a delegate that returns the conclusion; the main loop reads
   what it must judge. Small things (a handful of tool calls, one known file)
   it does itself, since a delegation costs more than it saves there.
6. **A delegate's report is a claim.** Check the diff, the output or a sample
   before reporting it as done.

## Brief shape per tier

How tightly to write depends on who reads it and for what.

- **Opus, implementation (fairly loose).** State the goal and why it matters,
  the context it cannot discover on its own, the constraints, and what done
  looks like. Leave the route to it. Over-specifying an Opus brief costs
  tokens and removes the judgment you are paying for.
- **Opus, second opinion (peer question).** Give it the problem, the
  evidence, the options you see and where you are unsure, and ask for what
  you may be missing. Do not hand it your conclusion to confirm. Treat the
  answer as a peer review and disagree on evidence. Use a fresh instance so it
  does not inherit the framing it is meant to challenge.
- **Sonnet, scoped work (a notch tighter).** Name the files or area, list the
  steps in order when order matters, give the output format, and say what not
  to touch. Say when to stop and report instead of improvising. One task per
  agent.
- **Sonnet, plan execution (detailed, complete).** Here Sonnet is a soldier:
  it does exactly what the brief says, step by step, with nothing skipped and
  nothing added. That makes the brief the whole quality ceiling. Write
  numbered steps, exact paths and commands, the acceptance check for each
  step, the edge cases and what to do in each, and the things that are out of
  scope. Anything left unsaid will not happen. Do not ask it to "use
  judgment" on an open design question; decide that first, then hand it the
  decision.
- **Haiku 5.5 / Sonnet (bulk).** One mechanical rule set, stated exactly,
  with two or three input and output examples. Split the data into batches
  small enough that a bad batch is cheap to redo, have each batch write to its
  own output file, and sample the results before merging. Never ask this tier
  to decide what the rules should be.

Long briefs go in a file (`local://<name>.md`); the prompt points at the file.

## Parallel lanes

Fleets run as one `task` call with several `tasks[]` items, or as eval
`agent()` / `workpool()` calls. Execution lanes run on Sonnet by default; use
Opus for lanes that need real judgment or for second-opinion lanes, and Haiku
for bulk cleanup. When assigning fleet lanes, stamp the `model` per lane in
the spec so the launch is mechanical and no routing decision happens at spawn
time.

## Exceptions

- If the operator explicitly names a model for a scoped task, honor it for that
  task only, then return to this policy.
- The operator can override any of this per session; absent that, this policy
  stands.
