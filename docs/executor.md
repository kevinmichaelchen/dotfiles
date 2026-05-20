# Executor

Executor is the shared local tool catalog for agent clients on this machine.
Dotfiles manage how clients connect to Executor; Executor owns the live runtime
state.

The default shared scope is:

- `~/.executor`

This repo pins Executor to `1.4.31`. Executor `1.4.28` was the first local
release where source state is clearly database-owned again. `executor.jsonc` is
an optional plugin manifest, not the source catalog.

## Client Wiring

Codex, Claude, OpenCode, and Crush all use the shared HTTP MCP daemon:

- `http://127.0.0.1:8788/mcp`

Do not wire normal agent clients to `executor mcp --scope ~/.executor` unless a
client cannot speak streamable HTTP MCP. Command-backed MCP spawns an Executor
runtime per client session, which can duplicate source state work and repeat
macOS Keychain probes.

## Ownership

Dotfiles own:

- The pinned Executor CLI version in Mise.
- MCP client wiring for Codex, Claude, OpenCode, and Crush.
- A macOS LaunchAgent for clients that need the HTTP daemon.
- Small operator helpers under `scripts/executor/`.

Executor owns:

- Sources.
- Secrets and OAuth Connections.
- Tool policies.
- Plugins.
- Execution history.
- Future workspace / nested-scope state.

Do not periodically rewrite Executor sources from dotfiles. That turns bash into
a second control plane and fights Executor's own runtime model.

Since Executor `1.4.28`, source configuration is no longer replayed from or
written back to `executor.jsonc`. Live source definitions, source credentials,
and source auth bindings are SQLite-backed runtime state.

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/executor/launchd-daemon.sh` | launchd entrypoint; runs the shared Executor daemon in foreground |
| `scripts/executor/restart.sh` | stops the daemon and restarts it through launchd |
| `scripts/executor/status.sh` | prints daemon reachability, version, scope, source inventory, and policy count |
| `scripts/executor/doctor.sh` | prints safe diagnostics for daemon, launchd, process, config, and keychain-prompt triage |
| `scripts/executor/ensure-readonly-search-policies.sh` | idempotently approves exact read-only Perplexity and Parallel search tools |
| `scripts/executor/common.sh` | shared constants and helper functions |

There is intentionally no steady-state source sync script. Add or edit sources
through Executor UI/CLI so policies, OAuth Connections, plugins, and future
nested scopes remain authoritative inside Executor.

## Chezmoi Boundary

Chezmoi should manage the pieces that are stable text config:

- agent client wiring that points at `http://127.0.0.1:8788/mcp`
- the launchd plist and foreground daemon entrypoint
- helper scripts and operator docs
- machine-wide policy bootstrap for exact low-risk tools

Chezmoi should not own `~/.executor/executor.jsonc` wholesale. On Executor
`1.4.28+`, that file should only be treated as an optional plugin manifest.
Sources, generated OpenAPI specs, secret references, and remote MCP auth
bindings belong in Executor's runtime database and should be edited through the
control plane.

If `doctor.sh` reports a lingering `sources` key in `executor.jsonc`, treat it
as legacy state. Do not port it into dotfiles; verify the live source in
Executor's UI/CLI and remove the stale config entry only after the database copy
is healthy.

## LaunchAgent

The macOS LaunchAgent is `com.kchen.executor-daemon`.

It runs:

```bash
scripts/executor/launchd-daemon.sh
```

That script activates Mise and then execs:

```bash
executor daemon run --foreground \
  --port 8788 \
  --hostname 127.0.0.1 \
  --scope ~/.executor
```

launchd supervises the foreground process with `KeepAlive`.

The Chezmoi LaunchAgent hook is intentionally idempotent. If the LaunchAgent is
already loaded, `chezmoi apply` leaves the daemon running instead of booting it
out and starting a fresh process. This avoids unnecessary keychain probes and
keeps source/OAuth state warm. Use `scripts/executor/restart.sh` or set
`EXECUTOR_FORCE_LAUNCHD_RELOAD=1` for an intentional launchd reload.

## Secrets

Executor source credentials should use Executor secret providers, not committed
env blocks or checked-in source definitions.

| Backend | Use When | Notes |
| --- | --- | --- |
| 1Password | API tokens already live in 1Password | Preferred for Exa, Perplexity, Parallel, Firecrawl, and similar source credentials |
| macOS Keychain | You specifically want OS-keychain storage | Encrypted at rest, but macOS can prompt when Executor probes or reads entries |
| file-secrets | Local throwaway development only | Plain JSON on disk; do not use for durable personal API tokens |

For Exa, keep the global `exa` source in `~/.executor`, keep the API key in
1Password, and bind the source credential to the 1Password-backed Executor
secret. The shell `EXA_API_KEY` template can remain for non-Executor CLIs, but
Executor sources should not rely on committed env wiring.

If macOS repeatedly asks for a Keychain password:

- Run `./scripts/executor/doctor.sh` and check whether multiple Executor
  processes are running.
- Avoid restarting launchd unless needed; `chezmoi apply` no longer restarts an
  already loaded Executor daemon by default.
- Keep Codex and Claude on the HTTP MCP URL so they do not spawn extra
  command-backed Executor runtimes.
- Prefer migrating source credentials to the 1Password provider so Executor does
  not need to store new source secrets in Keychain.
- Expect one-time prompts after an Executor binary upgrade if existing secrets
  still live in Keychain.

## Project Scopes

For now, global clients use `~/.executor`. As Executor's workspace / nested
scope support matures, project repos should move project-specific tools and
policies into their own Executor scopes instead of adding them to global
dotfiles.

Examples of project-specific sources that should not live in global dotfiles:

- A local Playwright MCP for one app.
- A design MCP only relevant to one UI repo.
- A repo-local state-parks or demo MCP.
- Repo-specific Nia indexes.

The expected future pattern is:

```bash
executor mcp --scope ~/.executor
executor mcp --scope /path/to/project
```

where the project scope can inherit from or layer over the global scope once
Executor exposes that workflow.

## Approval Policy

Executor's policy model is the right place for tool safety decisions. Rules live
at scope level and can match exact tools or namespace wildcards.

| Action | Use When |
| --- | --- |
| `approve` | A read-only or low-risk tool is noisy enough that repeated prompts slow work down |
| `require_approval` | A tool should always ask first, even if its source metadata says it is safe |
| `block` | A tool should be hidden from discovery and fail if invoked |

Best practice:

- Keep global `~/.executor` permissive only for clearly read-only tools.
- Require approval or block broad write namespaces globally.
- Put project-specific exceptions in project scopes once nested scopes are
  available.
- Let upstream MCP `destructiveHint` annotations require approval by default.
- Avoid encoding approval rules in dotfiles unless they are truly machine-wide
  policy.

This repo seeds two exact machine-wide approvals because they are read-only web
search tools used across many local projects:

| Pattern | Action | Why |
| --- | --- | --- |
| `perplexity_search.search.searchSearchPost` | `approve` | avoids repeated approval prompts for Perplexity Search |
| `parallel_search.search.webSearchV1betaSearchPost` | `approve` | avoids repeated approval prompts for Parallel Search |

Keep these exact rather than approving the whole namespace. If either API grows
write-capable operations later, those new tools should require review before
being approved.

## Manual Operations

```bash
# Show daemon + source inventory.
./scripts/executor/status.sh

# Show safe daemon/process/keychain diagnostics.
./scripts/executor/doctor.sh

# Restart the daemon through launchd.
./scripts/executor/restart.sh

# Ensure global read-only search approvals.
./scripts/executor/ensure-readonly-search-policies.sh

# Inspect the live control-plane OpenAPI spec.
curl -s http://127.0.0.1:8788/api/docs \
  | python3 -c 'import re,sys,json; m=re.search(r"<script id=\"swagger-spec\" type=\"application/json\">(.*?)</script>",sys.stdin.read(),re.S); print(json.dumps(json.loads(m.group(1)),indent=2))' \
  | jq '.info'

# Tail logs.
tail -f ~/Library/Logs/com.kchen.executor-daemon.log
tail -f ~/Library/Logs/com.kchen.executor-daemon.err.log
tail -f ~/.local/state/executor/logs/runtime.log
```

## Troubleshooting

- `status.sh` is the first stop. It fails fast if the runtime is unreachable.
- Runtime wedged? Run `restart.sh`.
- If `restart.sh` says the LaunchAgent is not loaded, run `chezmoi apply` from
  the real `~/dotfiles` checkout so launchd points at an existing script.
- Repeated Keychain prompts? Run `doctor.sh`; if there are multiple Executor
  processes, stop the extras and keep the launchd daemon as the shared runtime.
- Source auth broken? Fix it in Executor's UI/CLI, not in dotfiles.
- Project-only MCPs should move to project scopes when Executor's nested-scope
  flow is ready.
