# OpenCode v2

Mise owns the official `npm:@opencode/cli` package, tracking `latest` through
Mise. The old `github:anomalyco/opencode` declaration and v1-only plugins are
removed. The package's reviewed postinstall selects its platform binary; this
package alone opts into npm install scripts. `update: "disable"` leaves upgrades to Mise.

## Configuration and state

Mise links `dotfiles/.config/opencode/dotfiles.json` into the home config
directory. `OPENCODE_CONFIG` loads it as a native override layer; local
`opencode.json(c)`, credentials, session history, and `cli.json` remain app-owned.
The managed file uses v2's `mcp.servers`, `providers`, and `agents.title.model`.
The primary model stays local. Provider/model metadata comes from the upstream
catalog, rather than hand-maintained limits or pricing overrides.

The shell exports the override path. V2 uses a background service that retains
its startup environment. For an existing service, or clients launched outside
the configured shell, set its environment using the native CLI once:

```bash
opencode service set env OPENCODE_CONFIG "$HOME/.config/opencode/dotfiles.json"
```

This stops the service; the next OpenCode command starts it with the managed
layer. It does not rewrite the local application config. `opencode debug config`
shows loaded configuration sources.

V2 imports supported legacy credentials from `auth.json` into its SQLite database
on first startup. Keep a private backup while validating. Do not edit the
database, copy tokens into dotfiles, or restore a v1 binary against converted
v2 configuration. The terminal client migrates supported global `tui.json`
settings to app-owned `cli.json` when needed.

## Authentication

For occasional live authentication checks, use the project-scoped
[OpenCode authentication smoke test](../../../.agents/skills/opencode-auth-smoketest/SKILL.md)
at `.agents/skills/opencode-auth-smoketest/SKILL.md` from the repository root.
It sends minimal requests through the requested providers and distinguishes
stored credentials from successful inference. Tests use provider credits and
create local OpenCode sessions.

```bash
opencode auth list
opencode auth login openai       # choose ChatGPT Pro/Plus, not API key billing
opencode auth login openrouter   # enter your existing key interactively
opencode auth login fireworks-ai # enter your existing key interactively
opencode auth login venice       # enter your Venice AI key interactively
opencode mcp auth executor
```

Existing supported logins migrate automatically; log in again only if needed.
Credentials belong to OpenCode's local SQLite store, never the repository.
Venice AI is a built-in provider (`venice`); it needs no custom provider block
in the managed layer. Generate a key in the [Venice AI console](https://venice.ai/),
connect with the command above (or `/connect` → Venice AI), then use `/models`
to select an available Venice model. See the
[Venice AI setup instructions](https://opencode.ai/docs/providers/#venice-ai).
Environment keys must reach the server, not just an already-running client's
shell. `/connect` and `/models` provide the corresponding interactive controls.

Use the Claude subscription through Claude Code. Anthropic documents subscription
OAuth for its native apps; do not assume a Claude subscription supplies API
credits or a supported OpenCode subscription connection. Claude models accessed
through OpenRouter use separately billed API credits.

## Model choices

The primary model stays in app-owned config. Kevin currently uses Opus 5.5 for
his toughest work, GPT-6.1 Sol and GPT-6 Astra for difficult work and reviews,
and Sonnet 5.5 / GPT-6 Luna for lighter tasks. Treat this as workflow context,
not a benchmark ranking or a promise that subscription access works in every
client. Use Claude Code for the Claude subscription. The title agent uses
`openai/gpt-6-luna` through the existing ChatGPT connection.

The selected local default is `openrouter/deepseek/deepseek-v4.1-flash`:
OpenCode prioritizes fast execution alongside the Claude/Codex subscriptions
already used for difficult work. Switch to MiMo V2.6 Pro for its stronger
overall benchmark performance or an independent implementation attempt, and
GLM 5.3 for a terminal-coding challenger. This is a workflow preference, not a
universal quality ranking; measured speed varies by serving endpoint. Set the
root `model` field in app-owned `~/.config/opencode/opencode.json` to select
the default for new sessions; existing sessions retain their model selection.

The managed layer explicitly enables these catalog entries as optional models;
it does not choose a new default or restrict other providers/models. Connect
OpenRouter and Fireworks, then use `/models` to select an entry. A project's
provider policies, credentials, and upstream availability still apply.
Because this override layer loads after local global config, its explicit
enables override local disables for these entries; unrelated disables remain.

| Model               | OpenRouter ID (prefix with `openrouter/`) | Fireworks ID (prefix with `fireworks-ai/`)      |
| ------------------- | ----------------------------------------- | ----------------------------------------------- |
| MiMo V2.6 Pro       | `xiaomi/mimo-v2.6-pro`                    | —                                               |
| MiMo V2.6 Flash     | `xiaomi/mimo-v2.6-flash`                  | —                                               |
| GLM 5.3             | `z-ai/glm-5.3`                            | `accounts/fireworks/models/glm-5p3`             |
| GLM 5.3 Flash       | `z-ai/glm-5.3-flash`                      | `accounts/fireworks/models/glm-5p3-flash`       |
| DeepSeek V4.1 Flash | `deepseek/deepseek-v4.1-flash`            | `accounts/fireworks/models/deepseek-v4p1-flash` |
| MiniMax M3          | `minimax/minimax-m3`                      | `accounts/fireworks/models/minimax-m3`          |
| Kimi K3             | `moonshotai/kimi-k3`                      | `accounts/fireworks/models/kimi-k3`             |

IDs were checked against the installed v2 catalog on **2026-10-16**. MiMo's
Fireworks Pro-RL listing is an on-demand deployment, so it is not included as
a serverless option. Model entries set only `disabled: false`; pricing,
capabilities, variants, and limits continue to come from upstream catalog data.
OpenRouter retains `data_collection: "deny"`, which can restrict eligible
endpoints. Choosing an OpenRouter model spends OpenRouter credits, even when
Fireworks serves the request; direct Fireworks models spend Fireworks credits.

### Dated comparison: 2026-10-16

Use this snapshot to choose experiments, and refresh it before changing the
shortlist. Prices are USD per million tokens at the **named endpoint**, not the
cheapest price across OpenRouter routes. Cached input is a separate rate.

| Model               | Price source           |  Input | Cached input | Output |
| ------------------- | ---------------------- | -----: | -----------: | -----: |
| MiMo V2.6 Flash     | Xiaomi via OpenRouter  |  $0.14 |      $0.0028 |  $0.28 |
| MiMo V2.6 Pro       | Xiaomi via OpenRouter  | $0.435 |      $0.0036 |  $0.87 |
| GLM 5.3 Flash       | Fireworks              |  $0.15 |        $0.03 |  $0.50 |
| DeepSeek V4.1 Flash | Fireworks              |  $0.30 |       $0.006 |  $1.20 |
| MiniMax M3          | MiniMax via OpenRouter |  $0.30 |        $0.06 |  $1.20 |
| GLM 5.3             | Fireworks              |  $1.40 |        $0.26 |  $4.40 |
| Kimi K3             | Fireworks              |  $3.00 |        $0.30 | $15.00 |

Source: [OpenRouter's per-model endpoint API](https://openrouter.ai/api/v1/models/xiaomi/mimo-v2.6-pro/endpoints)
(`/api/v1/models/{author}/{slug}/endpoints`), cross-checked with Fireworks model
pages below. Endpoint prices differ from the catalog's model-level summary;
provider routing, quantization, service tier, caching, reasoning tokens, and
credit-purchase fees affect spend. These settings do not pin a serving endpoint.

Artificial Analysis (AA) supplies a common independent evaluation: Intelligence
Index **v4.3.2**, Terminal-Bench **4.0**, and SciCode. Scores and speed are copied
from its linked comparison pages, not combined from vendor launch benchmarks.

| Model                                 | AA index | Terminal-Bench 4.0 | SciCode | Output tokens/s | First token (s) |
| ------------------------------------- | -------: | -----------------: | ------: | --------------: | --------------: |
| [MiMo V2.6 Pro][aa-mimo-glm]          |       46 |                35% |     61% |          ~44–47 |            ~4.1 |
| [GLM 5.3 (Max)][aa-glm-kimi]          |       45 |                42% |     59% |              67 |            3.32 |
| [Kimi K3 (Max)][aa-glm-kimi]          |       44 |                13% |     59% |              44 |            3.18 |
| [GLM 5.3 Flash][aa-mimo-glm]          |       42 |                33% |     52% |              60 |            2.81 |
| [DeepSeek V4.1 Flash (Max)][aa-flash] |       39 |                27% |     52% |             179 |            1.12 |
| [MiMo V2.6 Flash][aa-flash]           |       38 |                23% |     51% |              60 |            3.22 |
| [MiniMax M3][aa-minimax]              |       29 |                 2% |     47% |              95 |            1.24 |

Higher benchmark scores and output speed are better; lower latency is better.
The AA index is not a percentage. AA marks SciCode under review. AA speed is
first-party API performance, or a provider median when first-party access is
unavailable; it does **not** measure the selected Fireworks/OpenRouter route.
MiMo Pro's range reflects different snapshots across AA comparison pages.
The OpenRouter endpoint API returned null throughput/latency fields during
this check; no inference or local speed benchmark was run.

The snapshot suggests considering MiMo Pro for broad benchmark performance,
GLM 5.3 for terminal coding, and GLM Flash / MiMo Flash / DeepSeek Flash for
lower-cost or faster work. MiniMax and Kimi remain comparison options, not
assumed upgrades. Kimi's AA long-context result (89% versus GLM's 80%) is one
reason to compare individual benchmarks rather than only the composite index.

X is a discovery and sentiment source, not measurement evidence. The bounded
70-post search on 2026-10-16 found heavy discussion of the
[OpenCode GLM Flash promotion](https://x.com/opencode/status/2110986357539754114)
and an [Agent Arena open-model update](https://x.com/arena/status/2110815995950731340).
Promotions and rankings are dated observations, not stable configuration defaults.

[aa-mimo-glm]: https://artificialanalysis.ai/models/comparisons/mimo-v2-6-pro-vs-glm-5-3-flash
[aa-glm-kimi]: https://artificialanalysis.ai/models/comparisons/glm-5-3-vs-kimi-k3
[aa-flash]: https://artificialanalysis.ai/models/comparisons/mimo-v2-6-flash-vs-deepseek-v4-1-flash
[aa-minimax]: https://artificialanalysis.ai/models/comparisons/mimo-v2-6-pro-vs-minimax-m3

### Updating model choices

Use the project-scoped
[opencode-model-curator skill](../../../.agents/skills/opencode-model-curator/SKILL.md)
from the repository root (`.agents/skills/opencode-model-curator/SKILL.md`). It
covers live research, bounded X discovery, objective comparison, catalog checks,
and v2 validation. Refresh IDs and sources rather than perpetuating this snapshot.

```bash
opencode models
opencode run --model openrouter/xiaomi/mimo-v2.6-pro "..."
opencode run --model fireworks-ai/accounts/fireworks/models/glm-5p3-flash "..."
opencode stats --cost --models
python3 scripts/check-opencode-v2.py
```

`opencode stats` replaces the removed v1 TokenScope plugin and slash command.
The Codex-auth plugin is removed because v2 includes ChatGPT login. Other local
plugins must support the new v2 API; merely renaming `plugin` to `plugins` does
not port them.

## References

- [V1 migration](https://opencode.ai/v2/docs/migrate-v1/)
- [V2 installation](https://opencode.ai/v2/docs/)
- [Native provider login and credential migration](https://opencode.ai/v2/docs/cli/providers/)
- [Models and selection](https://opencode.ai/v2/docs/models/)
- [Plugin migration requirements](https://opencode.ai/v2/docs/plugins/)
- [Fireworks GLM 5.3](https://fireworks.ai/models/fireworks/glm-5p3)
- [Fireworks GLM 5.3 Flash](https://fireworks.ai/models/fireworks/glm-5p3-flash)
- [Fireworks MiniMax M3](https://fireworks.ai/models/fireworks/minimax-m3)
- [Fireworks Kimi K3](https://fireworks.ai/models/fireworks/kimi-k3)
- [Fireworks MiMo Pro-RL (on-demand)](https://fireworks.ai/models/fireworks/mimo-v2p6-pro-rl)
- [OpenRouter Compare](https://openrouter.ai/compare/xiaomi/mimo-v2.6-pro/z-ai/glm-5.3)
- [Fireworks standard pricing](https://docs.fireworks.ai/serverless/pricing)
- [OpenRouter live model catalog](https://openrouter.ai/api/v1/models)
- [OpenRouter pricing and fees](https://openrouter.ai/pricing)
- [OpenAI API pricing](https://developers.openai.com/api/docs/pricing)
- [Anthropic credential use](https://code.claude.com/docs/en/legal-and-compliance)
