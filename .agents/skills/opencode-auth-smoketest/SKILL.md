---
name: opencode-auth-smoketest
description: Smoke-test this repository's OpenCode provider authentication with minimal live inference through Fireworks AI and OpenRouter, using the requested model and snapshot. Use for checking whether stored credentials actually work; not for model benchmarks or shortlist maintenance.
---

# OpenCode Authentication Smoke Test

Read `dotfiles/.config/opencode/README.md` for the shared configuration layer
and native credential ownership. Test the user's requested providers and model;
when unspecified, use Fireworks AI and OpenRouter with DeepSeek V4.1 Flash 1017.
A smoke-test request authorizes small paid inference requests on those routes.
Do not change defaults, configuration, credentials, or provider routing to make
a check pass. Never print keys, tokens, or raw credential files.

## Discover the installed interface

Run these from the user's project so location-scoped policies and credentials
apply:

```bash
opencode --version
opencode auth list
opencode run --help
opencode models | rg '^(fireworks-ai|openrouter)/.*deepseek.*flash.*1017'
```

`auth list` shows stored connections, not proof of valid authentication.
`models` shows catalog availability, not proof of inference access. On v2.1.4,
`opencode models` accepts no provider positional argument; filter its output.
If OpenCode cannot write its normal log or reach its local service under the
sandbox, request the necessary execution access rather than relocating its
state and inadvertently testing without the user's credentials.

Confirm exact IDs from the installed catalog. These were available on
2026-10-23; do not silently substitute the undated alias, a priority/spot route,
or another snapshot if the requested entry disappears:

| Route | Full OpenCode model ID |
| --- | --- |
| Fireworks AI | `fireworks-ai/accounts/fireworks/models/deepseek-v4p1-flash-1017` |
| OpenRouter | `openrouter/deepseek/deepseek-v4.1-flash-1017` |

## Send minimal requests

Use a fresh session for each provider, with an explicit model. Leave the
existing background service and its configuration in place; do not restart it
or use an isolated server unless diagnosing a specific service problem.

```bash
opencode run \
  --model fireworks-ai/accounts/fireworks/models/deepseek-v4p1-flash-1017 \
  --title 'Authentication smoke test: Fireworks AI' \
  --format json \
  'Authentication smoke test. Do not use any tools or read or modify files. Reply with exactly: AUTH_OK'

opencode run \
  --model openrouter/deepseek/deepseek-v4.1-flash-1017 \
  --title 'Authentication smoke test: OpenRouter' \
  --format json \
  'Authentication smoke test. Do not use any tools or read or modify files. Reply with exactly: AUTH_OK'
```

Adapt only the model/provider selection when the user requests other routes.
Do not pass `--continue`, attach files, enable automatic tool approvals, or run
coding tasks. OpenCode can still include its normal agent context, generate
session titles, and write session/log state; this is not a zero-token API ping.
Direct Fireworks requests spend Fireworks credits; OpenRouter requests spend
OpenRouter credits. Preserve OpenRouter's existing `data_collection: "deny"`.
This test does not pin or prove the underlying serving provider on OpenRouter.

One completed request per route is enough. Bound a hanging request to roughly
60 seconds, cancel only that test process if necessary, and report a timeout as
inconclusive. Retry only when a specific transient error justifies it; avoid
repeated paid requests for a deterministic failure.

## Interpret and report

Inspect the JSON events and process completion, not just the exit code. A
completed run with an assistant text event containing `AUTH_OK` and no error
confirms the selected route accepted authentication and completed inference.
An unexpected answer still demonstrates inference access, but fails the exact
response check; report both facts separately.

Classify failures using the actual provider error:

- Invalid, expired, or missing credentials: authentication failed or unavailable.
- Insufficient credits: inference blocked by billing; do not label the key invalid.
- Model/access denial, missing endpoint, or routing/privacy conflict: report the
  access or routing issue without claiming credentials are invalid.
- Rate limits, network failures, or timeouts: inconclusive for authentication.

Report the OpenCode version, each exact route, observed response or error, and
whether live inference succeeded. Distinguish catalog-only or stored-credential
checks from live verification when blocked. Mention that tests create local
sessions and use provider credits; do not claim files or state were untouched.
If login is needed, point to native `/connect` or `opencode auth login` for the
affected provider; never ask the user to paste a secret into chat or the repo.
