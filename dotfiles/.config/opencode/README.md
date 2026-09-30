# OpenCode v2

Mise owns the official `npm:@opencode/cli` package, pinned to `2.0.20`. The old
`github:anomalyco/opencode` declaration and v1-only plugins are removed. The
package's reviewed postinstall selects its platform binary; this package alone
opts into npm install scripts. `update: "disable"` leaves upgrades to Mise.

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

```bash
opencode auth list
opencode auth login openai       # choose ChatGPT Pro/Plus, not API key billing
opencode auth login openrouter   # enter your existing key interactively
opencode auth login fireworks-ai # enter your existing key interactively
opencode mcp auth executor
```

Existing supported logins migrate automatically; log in again only if needed.
Credentials belong to OpenCode's local SQLite store, never the repository.
Environment keys must reach the server, not just an already-running client's
shell. `/connect` and `/models` provide the corresponding interactive controls.

Use the Claude subscription through Claude Code. Anthropic documents subscription
OAuth for its native apps; do not assume a Claude subscription supplies API
credits or a supported OpenCode subscription connection. Claude models accessed
through OpenRouter use separately billed API credits.

## Model choices

Start with GPT-6.1 Sol through the included ChatGPT allowance, if available in
`/models`. Use Claude Code's subscribed Sonnet/Opus models for difficult reviews
and compare results. These are workflow recommendations, not measured quality
rankings. Subscription limits still apply.

For API-funded work, try GLM 5.3 Flash before a more expensive model. The title
agent uses `openai/gpt-6-luna` through the existing ChatGPT connection, avoiding
a required second provider or separate API-funded title requests.
OpenRouter requests keep the existing `data_collection: "deny"` routing policy,
which can limit eligible endpoints. Fireworks is also built in and needs no
custom provider declaration.

Standard prices checked 2026-09-29, USD per million tokens:

| Model | Input | Cached input | Output | Suggested use |
| --- | ---: | ---: | ---: | --- |
| GPT-6 Luna (OpenAI API, short context) | $0.10 | $0.01 | $0.50 | Compare for lightweight work if API access is available |
| GLM 5.3 Flash (Fireworks / OpenRouter) | $0.15 | $0.03 | $0.50 | Inexpensive paid fallback |
| DeepSeek V4.1 Flash (Fireworks / OpenRouter) | $0.30 | $0.006 | $1.20 | Alternative when repeated input gets cache hits |
| GLM 5.3 (Fireworks / OpenRouter) | $1.40 | $0.26 | $4.40 | Escalation candidate; compare on your own tasks |
| Kimi K3 (Fireworks / OpenRouter) | $3.00 | $0.30 | $15.00 | Use when it earns its higher cost on a specific task |

GPT-6 Luna is slightly cheaper than GLM Flash at short contexts, but an OpenAI
subscription does not establish API access or billing. OpenAI long-context
pricing differs. Provider routing, caching, reasoning output, retries, and
OpenRouter credit-purchase fees affect actual spend. No paid benchmark or model
request was run during this migration. Check current prices before budgeting.

```bash
opencode models
opencode run --model openai/gpt-6.1-sol "..."
opencode run --model openrouter/z-ai/glm-5.3-flash "..."
opencode run --model fireworks-ai/accounts/fireworks/models/glm-5p3-flash "..."
opencode stats --cost --models
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
- [Fireworks standard pricing](https://docs.fireworks.ai/serverless/pricing)
- [OpenRouter live model catalog](https://openrouter.ai/api/v1/models)
- [OpenRouter pricing and fees](https://openrouter.ai/pricing)
- [OpenAI API pricing](https://developers.openai.com/api/docs/pricing)
- [Anthropic credential use](https://code.claude.com/docs/en/legal-and-compliance)
