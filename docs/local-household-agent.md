# Local household agent on the Mac mini

Target: Kevin's **2024 Mac mini, Apple M4, 16 GB unified memory**. Research
checked **2026-10-16**. This is a proposed setup, not an installed service.

The local agent manages events, reminders, people to contact, appointments,
and grocery lists. Claude and Codex already handle code generation and difficult
engineering work. Select local models for structured tool use, instruction
following, memory use, and end-to-end response latency rather than coding rank.

## Model shortlist

This order is a recommendation for the household workload, not a universal
benchmark ranking. Package sizes are download sizes, not total runtime RAM.

| Model           | Package / quantization                                   | Why it fits                                                                     | Evidence and limitations                                                                                                                                                         |
| --------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **LFM2.5-2.6B** | MLX 8-bit **2.67 GB**; official GGUF Q8_0 also available | First model to try for text-based tool use, extraction, and household workflows | Liquid explicitly documents Hermes and OpenClaw integration. Small enough to try higher precision before extreme compression. No measured speed on this Mac mini.                |
| **Qwen3.5-9B**  | GGUF Q4_K_M **~5.3 GB**                                  | Main comparison model if LFM struggles with instructions or multi-step tasks    | Hermes documents a Mac setup. A base M4 16 GB community result measured ~20 tokens/s with a different MLX 4-bit pack at 4K context; this is not a speed prediction for the GGUF. |
| **Bonsai 2 9B** | MLX 2-bit **3.46 GB**, including vision                  | Compact screenshot, receipt, and document understanding, with tool calling      | Released October 15. The headline 2 GB is not the complete MLX pack. Runtime compatibility and multi-turn tool behavior need validation.                                         |
| **Raptor 0.6**  | JANG 6-bit **3.7 GB**                                    | An alternative if Osaurus's native Mac workflows suit the chosen apps           | Tuned for Osaurus's tools; that does not establish Hermes/OpenClaw compatibility. Requires Osaurus 0.25.0+ for its architecture support.                                         |

Sources: [Liquid integration guide][liquid-agents], [LFM MLX formats][lfm-quants],
[official GGUF files][lfm-gguf], [Hermes Mac guide][hermes-mac],
[base M4 community measurement][m4-qwen], [Bonsai model card][bonsai-card], and
[Raptor model/runtime details][raptor].

The 16 GB budget includes macOS, the agent, tools, model weights, runtime
buffers, vision components, and context cache. Keep one model loaded initially.
The actual context allocation matters more than the advertised maximum.
Local inference avoids a hosted per-token bill; electricity, disk space, and
any paid external tools remain separate costs.

### Objective evidence relevant to household tasks

Liquid's own evaluation compares these models under its reported setup. These
are **vendor-run results**, not independent household-task success rates or
measurements of the selected quantized packages. Higher scores are better.

| Benchmark                           | LFM2.5-2.6B | Qwen3.5-9B |
| ----------------------------------- | ----------: | ---------: |
| BFCL v4: function calling           |       56.88 |      60.13 |
| ToolSandbox: tool-based interaction |       77.83 |      76.44 |
| IFBench: instruction following      |       59.17 |      56.47 |

Source: [Liquid's model-card comparison][lfm-card]. These mixed results justify
comparing both models; parameter count alone does not pick a winner.

PrismML's separate evaluation reports Bonsai 2 9B at **78.02** on BFCL v4 Mobile
versus **82.02** for its Qwen3.5 9B baseline, and **73.02** versus **85.25** on
tau2-Bench. Compression preserves different tasks differently. Do not compare
BFCL v4 Mobile directly with Liquid's BFCL v4 row or merge scores from different
harnesses into a single ranking. [PrismML evaluation][bonsai-release].

No shared base-M4 speed comparison was found for this shortlist. Raptor's
~105 tokens/s and LFM's 220 tokens/s are publisher measurements on **M5 Max**
hardware, with different setups; they are not Mac mini estimates.
[Raptor measurements][raptor], [Liquid measurements][lfm-card].

### Discovery on X

Bounded read-only searches on 2026-10-16 retrieved 120 posts for small models and
25 more for household-agent compatibility. Some results were unrelated and were
excluded. Raw captures remain under gitignored `.context/x/`; web extracts and
model-card captures remain under `.context/local-models-2026-10-16/`.

Useful leads included [PrismML's release announcement][prism-x],
[Atomic Chat's Bonsai integration][atomic-x], and
[a local calendar/memory demo][liquid-x]. Treat posts as discovery
and qualitative context. A demo, integration announcement, or popularity count
does not establish reliability in the chosen agent.

Tencent's [Hy-MT2-1.8B][tencent-mt] has a 440 MB extreme variant, but it is a
translation specialist, so it is not on the general household-agent shortlist.
Its translation results should not be treated as general agent benchmarks.

## Choose the agent by its integrations

Hermes and OpenClaw can use a local OpenAI-compatible server. Liquid documents
both with LFM2.5-2.6B. Osaurus is a separate option with models tuned for its
Mac tool surface. The final agent choice is open until the actual household
apps and delivery channel are identified. [Liquid setup][liquid-agents],
[OpenClaw local backends][openclaw-local], [Hermes local models][hermes-local].

| Need                    | Concrete integration to select                                           | Observable completion                                                                |
| ----------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| Events and appointments | Actual calendar account; availability, timezone, and event creation      | Read back the saved event ID, time, and calendar                                     |
| Reminders               | Actual reminder/task store plus a durable scheduler and delivery channel | A stored due date and a delivered test notification                                  |
| People to contact       | Contacts lookup and a persistent follow-up list                          | Correct contact ID and a saved follow-up task; sending messages is a separate action |
| Groceries               | Shared list or inventory fed by purchases, receipts, or manual updates   | A persisted quantity/list change; retry does not create a duplicate                  |
| Household preferences   | Persistent facts retrieved when relevant                                 | Saved preferences remain available after restarting the agent                        |

The model cannot observe an empty fridge without data. A shopping-list tool
and a receipt/manual-update workflow are concrete starting points. The model
also does not keep time by itself: reminders need a scheduler, persisted state,
and a working notification destination. Keep calendar/task stores authoritative;
chat history alone is not proof an appointment or reminder exists.

## First local-serving experiment

This recipe is for the **Mac mini**, not the MacBook running the research.
It is documented for review and has not been executed. It downloads weights
and starts a local process when run. No model, agent, background service, or
household account was installed or connected by this PR.

If adopting the recipe, route the runtime installation through `mise/config.toml`
and its normal lockfile workflow. The current repository does not declare a
household-agent runtime; do not run a second installer alongside Mise. Use an
existing compatible `llama-server` for the experiment if one is already installed.

The official LFM repository contains `LFM2.5-2.6B-Q8_0.gguf`. Starting with
Q8_0 trades some memory for precision on this 16 GB machine. Use a stable API
alias so the agent configuration does not depend on a local file path:

```bash
llama-server \
  -hf LiquidAI/LFM2.5-2.6B-GGUF:Q8_0 \
  --alias household-local \
  --host 127.0.0.1 \
  --port 8080 \
  --jinja \
  -c 65536 \
  -fa on \
  -ngl 99 \
  --temp 0.1 \
  --top-k 50 \
  --repeat-penalty 1.1
```

This adapts [Liquid's serving recipe][liquid-agents] to Q8_0, loopback, a stable
alias, and 64K context. The 64K starting window accommodates Hermes's documented
minimum while avoiding an unmeasured assumption that the full 128K window is
necessary. Verify real memory use, prefill latency, and tool calls on the mini.
Check the installed server supports the model template; `--jinja` enables its
tool-call handling. [Server flags][llama-server], [Hermes context guidance][hermes-mac].

Confirm the server reports `household-local` before selecting it in the agent:

```bash
curl --fail --silent --show-error http://127.0.0.1:8080/v1/models
```

For an **already installed Hermes**, the corresponding settings from Liquid's
guide are below. These commands change app-owned config; use them only after
choosing Hermes for the experiment. Match the agent's context to the server:

```bash
hermes config set model.provider custom
hermes config set model.base_url http://127.0.0.1:8080/v1
hermes config set model.default household-local
hermes config set model.context_length 65536
hermes config set model.api_mode chat_completions
hermes config set agent.tool_use_enforcement true
```

Liquid specifically recommends tool-use enforcement because otherwise the model
can describe an action without calling its tool. For OpenClaw, follow its
[custom local provider setup][openclaw-local] using the same base URL, alias,
and actual context window; select the provider/model for the desired agent.
This document does not apply either agent's config globally.

An OpenAI-compatible HTTP endpoint alone does not prove tool compatibility.
OpenClaw documents raw tool-looking text as a parsing/compatibility failure,
not a completed action. Fix the serving template/parser instead of executing
arbitrary JSON extracted from a model response. Use the agent's supported
tool discovery to keep schemas manageable. [OpenClaw troubleshooting][openclaw-local].

## Acceptance before daily use

Use a test calendar/list and concrete expected records to measure the chosen
model, quantization, server, and agent together. Record passed/total cases,
malformed calls, duplicate writes, latency, and peak RAM; do not invent
subjective autonomy or household-intelligence scores.

1. Request a reminder with an explicit date, time, and timezone. Read back the
   stored record and verify its notification arrives with the chat idle.
2. Create a test appointment only in a supplied free slot. Verify its saved
   calendar, time, and ID. Test a conflicting slot as a separate case.
3. Resolve an ambiguous contact without choosing the wrong person; persist a
   follow-up task and check it after restart.
4. Add groceries, retry the same operation, and verify the list has no duplicate.
   Check a receipt/image workflow separately if using a vision model.
5. Restart the agent and confirm preferences, scheduled work, and task state
   persist. Measure tool calls, not just fluent chat responses.

No cases have been run on the mini yet. Household apps, accounts, notification
channel, and agent selection remain deployment inputs. A follow-up that installs
or configures the selected stack should add only its scoped Mise/app settings.

For future updates, use the project-scoped
[local-household-agent skill](../.agents/skills/local-household-agent/SKILL.md).

[liquid-agents]: https://docs.liquid.ai/examples/agent-harnesses
[lfm-quants]: https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX-4bit
[lfm-gguf]: https://huggingface.co/LiquidAI/LFM2.5-2.6B-GGUF/tree/main
[lfm-card]: https://huggingface.co/LiquidAI/LFM2.5-2.6B
[hermes-mac]: https://hermes-agent.nousresearch.com/docs/guides/local-llm-on-mac
[hermes-local]: https://hermes-agent.nousresearch.com/docs/user-guide/local-models
[openclaw-local]: https://docs.openclaw.ai/gateway/local-models
[m4-qwen]: https://omlx.ai/benchmarks/performance/1d4n9ox1
[bonsai-card]: https://huggingface.co/prism-ml/Ternary-Bonsai-2-9B-mlx-2bit
[bonsai-release]: https://prismml.com/news/bonsai-2-family
[raptor]: https://osaurus.ai/models/raptor-06
[prism-x]: https://x.com/PrismML/status/2110823964650164348
[atomic-x]: https://x.com/atomic_chat_hq/status/2110856789235519549
[liquid-x]: https://x.com/ShubhamMal72313/status/2095671912118796450
[tencent-mt]: https://huggingface.co/tencent/Hy-MT2-1.8B-GGUF
[llama-server]: https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md
