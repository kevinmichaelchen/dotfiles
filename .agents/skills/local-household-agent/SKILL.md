---
name: local-household-agent
description: Research, compare, and plan this repository's local household assistant for Kevin's 16GB M4 Mac mini. Use for local model or Hermes/OpenClaw/Osaurus choices and calendar, reminder, contact, appointment, or grocery workflows; not for OpenCode coding-model maintenance.
---

# Local Household Agent

Read `docs/local-household-agent.md` for the hardware, dated shortlist, objective
evidence, serving recipe, and unresolved integration choices. The target is the
2024 M4 Mac mini with 16 GB RAM, not whichever computer runs the agent session.
Claude/Codex handle coding; this agent serves household tasks.

## Research and comparison

- Inspect existing repo/app setup first. Identify the actual calendar, reminder,
  contacts, grocery store, and notification channel before choosing connectors.
  Read-only research does not require account connection or installation.
- Use current primary lab/model cards, runtime docs, and agent integration docs.
  Use bounded read-only X discovery for recent releases and qualitative reports;
  try Birdclaw cache before live bird searches when available. Keep raw captures
  under gitignored `.context/`, not in the PR. Record date, queries, scope, and gaps.
- Compare actual package/quantization size, runtime and context memory, M4
  prefill/first-answer latency, decode speed, and task-relevant tool/instruction
  benchmarks. Label vendor versus independent/community results and hardware.
  Do not turn M5 Max speeds into M4 predictions, packed weight sizes into peak
  RAM, or advertised maximum context into a verified working memory budget.
- Prefer function-calling, instruction-following, and multi-turn tool evidence
  over coding rankings. Keep benchmark versions, harnesses, quantizations, and
  inference settings explicit. BFCL v4 Mobile is not interchangeable with BFCL v4.
  No shared measurements means unavailable, not an invented emoji rating.
- Verify exact model artifacts and runtime support. Bonsai marketing footprints
  can omit vision/pack overhead. Raptor's Osaurus tuning is not evidence it works
  equally well in Hermes/OpenClaw. Tencent translation/OCR specialists need a
  matching task rather than a general-assistant recommendation.

## Setup boundaries

- Keep the model, inference server, agent, scheduler, persistent stores, and
  connectors distinct. A model speaking JSON does not prove structured tool
  dispatch; successful dispatch does not prove the target record was saved.
- Preserve the existing OpenCode default and other coding-agent settings.
  Route any requested runtime install through Mise and its lockfile workflow.
  Keep household accounts, credentials, personal data, and app runtime state out
  of Git. A research/setup PR should not silently install or connect the stack.
- Check the chosen agent's current context requirements and tool parser against
  the serving backend. Match API alias and actual context allocation on both
  sides. Liquid's Hermes recipe calls for tool-use enforcement; verify current
  docs instead of copying old fields blindly.
- Make reminders durable and connect a notification destination. Calendar/task
  stores are authoritative; model prose or chat memory is not a saved reminder.
  Grocery depletion requires purchase, inventory, receipt, or manual observations.
  Selecting contacts and scheduling follow-ups does not authorize sending messages.

## Validation and delivery

Validate proposed commands/config syntax without executing installation or
downloads as an incidental docs check. Distinguish documented recipes, runtime
checks, and inference tests actually run on the mini. For an authorized pilot,
measure saved event/task IDs and timestamps, delivered notifications after idle
or restart, malformed tool calls, duplicate writes, latency, and peak RAM using
test data. Use deterministic outcomes rather than subjective quality scores.

Update the existing guide and its source links together. Place descriptive
reference-style X links inline beside relevant model and integration claims in
both the Markdown guide and PR body; distinguish lab announcements, demos, and
community experiments from independently measured evidence. Format changed Markdown
with oxfmt. For a requested PR, keep the visible model-choice table concise and
put evidence, setup details, and remaining deployment inputs under For machines;
honor the user's preference for no PR diagram.
