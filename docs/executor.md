# Executor

Executor is the shared local tool catalog for agent clients on this machine.
Dotfiles manage how clients connect to Executor; Executor owns the live runtime
state.

The default shared scope is:

- `~/.executor`

## Client Wiring

Codex and Claude use command-backed MCP through the Mise shim:

```bash
~/.local/share/mise/shims/executor mcp --scope ~/.executor
```

OpenCode and Crush are still URL-backed clients, so launchd keeps the local
daemon endpoint available:

- `http://127.0.0.1:8788/mcp`

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

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/executor/launchd-daemon.sh` | launchd entrypoint; runs the shared Executor daemon in foreground |
| `scripts/executor/restart.sh` | stops the daemon and restarts it through launchd |
| `scripts/executor/status.sh` | prints daemon reachability, version, scope, source inventory, and policy count |
| `scripts/executor/ensure-readonly-search-policies.sh` | idempotently approves exact read-only Perplexity and Parallel search tools |
| `scripts/executor/common.sh` | shared constants and helper functions |

There is intentionally no steady-state source sync script. Add or edit sources
through Executor UI/CLI so policies, OAuth Connections, plugins, and future
nested scopes remain authoritative inside Executor.

## Chezmoi Boundary

Chezmoi should manage the pieces that are stable text config:

- agent client wiring that points at `executor mcp --scope ~/.executor`
- the launchd plist and foreground daemon entrypoint
- helper scripts and operator docs
- machine-wide policy bootstrap for exact low-risk tools

Chezmoi should not own `~/.executor/executor.jsonc` wholesale. That file can
contain source definitions, generated OpenAPI specs, secret references, and
remote MCP connection details that drift as Executor evolves. Treating it as a
rendered dotfile makes Chezmoi a second source catalog and can overwrite live
OAuth-backed sources.

If a stale source in `executor.jsonc` clobbers live Executor state, remove only
that entry and repair the live source through the control plane. For Atlassian,
the expected live source auth is:

```json
{
  "kind": "oauth2",
  "connectionId": "atlassian_oauth"
}
```

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
- Atlassian source present but zero tools? Check whether `executor.jsonc`
  contains an `atlassian` source entry. A stale entry can sync without OAuth and
  replace the live source with `auth: none`. Remove that stale config-file entry,
  bind the live source to the `atlassian_oauth` connection, and run the
  MCP-specific source refresh.
- Source auth broken? Fix it in Executor's UI/CLI, not in dotfiles.
- Project-only MCPs should move to project scopes when Executor's nested-scope
  flow is ready.
