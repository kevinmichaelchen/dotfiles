# Executor

Executor is the local execution layer for shared agent tooling in this repo.
Codex and Claude talk to one local MCP endpoint:

- `http://127.0.0.1:8788/mcp`

That endpoint is backed by a local Executor runtime plus a sync script that
registers MCP and OpenAPI sources.

## Architecture

| Component | Role |
| --- | --- |
| Codex / Claude | MCP clients that call Executor |
| Executor runtime (`executor daemon run`) | Local tool catalog; persists runtime state under `~/.executor` |
| `scripts/executor/sync.sh` | Reconciles the desired source inventory into Executor |
| `scripts/executor/launchd-sync.sh` | Rebuilds shell env for launchd-driven runs |
| `scripts/executor/restart.sh` | Stops the runtime and re-runs sync |
| `scripts/executor/status.sh` | Prints runtime + source inventory |
| LaunchAgent | Starts sync on login and every 15 minutes |

## Source Types

Every source is either:

1. **Hosted remote MCP** — `streamable-http` or `sse` endpoint, auth via Executor-managed headers or OAuth connections.
   - Examples: DeepWiki, grep, Exa, Parallel Search MCP, Atlassian Rovo MCP, GitHub remote MCP, Firecrawl remote MCP.
2. **OpenAPI** — baseUrl + spec + headers.
   - Examples: Executor control plane, Perplexity Search.

There are **no stdio MCP bridges**. Every source is a plain HTTP endpoint that
Executor speaks to directly.

## Env Contract

Sources register only when their credentials are present.

| Source | Env vars | Auth form |
| --- | --- | --- |
| GitHub | `GITHUB_PERSONAL_ACCESS_TOKEN` | `Authorization: Bearer <PAT>` |
| Firecrawl | `FIRECRAWL_API_KEY` | `Authorization: Bearer <key>` |
| Atlassian Rovo | Preferred: persisted Executor connection `atlassian_oauth`. Fallback: `ATLASSIAN_EMAIL` + `ATLASSIAN_API_TOKEN` (Basic) or `ATLASSIAN_API_KEY` (Bearer) | OAuth preferred; token auth fallback |
| Perplexity | `PERPLEXITY_API_KEY` | `Authorization: Bearer <key>` |
| Parallel | `PARALLEL_API_KEY` | `Authorization: Bearer <key>` |
| Exa | `EXA_API_KEY` | `Authorization: Bearer <key>` |
| DeepWiki / grep | — | none |

Secrets live in `~/.config/shell/*.sh` fragments sourced by `launchd-sync.sh`.
`sync.sh` copies those values into Executor's own secret store and references
them from source definitions, so `executor.jsonc` does not need raw API keys.
Manual `sync.sh` runs also reload those fragments first so secret rotations do
not depend on the caller's current shell exports.

## Source Registry

This is the canonical map of the Executor sources managed by this repo, their
transport, the namespace they register under, the Executor secret or connection
name they use at runtime, and where the backing credential is sourced.

| Source | Namespace | Protocol | Executor auth ref | Shell/env source |
| --- | --- | --- | --- | --- |
| DeepWiki | `deepwiki` | `MCP` | none | no credential |
| grep | `grep` | `MCP` | none | no credential |
| Exa | `exa` | `MCP` | secret `exa_api_key` via `Authorization: Bearer` | `~/.config/shell/exa.sh` from `chezmoi/dot_config/shell/exa.sh.tmpl` using `op://Software/Exa/EXA_API_KEY` |
| Parallel Search | `parallel_search` | `MCP` | secret `parallel_api_key` via `Authorization: Bearer` | `~/.config/shell/parallel.sh` from `chezmoi/dot_config/shell/parallel.sh.tmpl` using `op://Software/Parallel/PARALLEL_API_KEY` |
| GitHub | `github` | `MCP` | secret `github_pat` via `Authorization: Bearer` | `~/.config/shell/github.sh` from `chezmoi/dot_config/shell/github.sh.tmpl`; prefers `gh auth token`, falls back to `op://Software/GitHub/GitHub Personal Access Token` |
| Firecrawl | `firecrawl` | `MCP` | secret `firecrawl_api_key` via `Authorization: Bearer` | `~/.config/shell/firecrawl.sh` from `chezmoi/dot_config/shell/firecrawl.sh.tmpl` using `op://Software/Firecrawl/FIRECRAWL_API_KEY` |
| Atlassian Rovo | `atlassian` | `MCP` | preferred connection `atlassian_oauth`; fallback secret `atlassian_basic_token` via `Authorization: Basic`; optional fallback secret `atlassian_api_key` via `Authorization: Bearer` | `~/.config/shell/jira.sh` from `chezmoi/dot_config/shell/jira.sh.tmpl` provides `JIRA_USERNAME` and `JIRA_API_TOKEN` from `op://Software/JIRA-Aspira/JIRA_API_TOKEN`; `~/.config/shell/atlassian.sh` is also sourced if present for `ATLASSIAN_*` overrides |
| Perplexity Search | `perplexity_search` | `OpenAPI` | secret `perplexity_api_key` via `Authorization: Bearer` header binding | `~/.config/shell/perplexity.sh` from `chezmoi/dot_config/shell/perplexity.sh.tmpl` using `op://Software/Perplexity/PERPLEXITY_API_KEY` |
| Executor control plane | `executor_control` | `OpenAPI` | none | live OpenAPI spec is pulled from the local runtime at `http://127.0.0.1:8788/api/docs` |

Notes:

- Executor secret ids such as `parallel_api_key` and `exa_api_key` live in the
  Executor scope's secret store and are created or updated by
  `scripts/executor/sync.sh`.
- The shell fragments above are the launchd-facing credential bridge.
  `scripts/executor/launchd-sync.sh` and manual `scripts/executor/sync.sh` runs
  both source them before reconciling Executor state.
- Source registration itself lives in `scripts/executor/sync.sh`: `reconcile_mcp`
  is used for MCP sources and `reconcile_openapi` is used for OpenAPI sources.

## Atlassian auth

Preferred path: complete a one-time OAuth consent flow so Executor stores the
`atlassian_oauth` connection in the current scope. Once that connection exists,
`sync.sh` keeps the Atlassian MCP source on OAuth automatically.

Fallback path: Atlassian Rovo MCP also accepts API-token auth when an org admin
has enabled it. Personal API tokens use Basic auth, service-account API keys
use Bearer. Tokens are not bound to a `cloudId`, so pass it per call.

See
[Atlassian docs: Configuring authentication via API token](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/).

## Startup Flow

1. macOS launchd loads `com.kchen.executor-sync`.
2. The LaunchAgent runs `scripts/executor/launchd-sync.sh`.
3. That script reconstructs `PATH`, activates Mise, and sources the credential
   fragments listed in `EXECUTOR_LAUNCHD_ENV_FILES`.
4. It execs `scripts/executor/sync.sh`.
5. `sync.sh` hits `GET /api/scope`. If the runtime isn't up, it starts
   `executor daemon run --port 8788 --hostname 127.0.0.1 --scope ~/.executor`
   via a detached tmux launch wrapper and waits for `/api/docs`.
6. For each desired source, `sync.sh` compares with `GET /api/scopes/:id/{mcp,openapi}/sources/:ns` and PATCHes, POSTs, or DELETE+POSTs as needed. On add/patch it triggers a tool refresh.
7. If `~/.executor/executor.jsonc` is still in the legacy object-shaped format,
   `sync.sh` backs it up and replaces it with a modern empty `sources` array
   before reconciliation.
8. Secret-backed sources are written as secret references, not literal tokens.
9. Executor persists sources in SQLite, so subsequent runs are cheap — unchanged sources return a "already up to date" line without touching the server.

## Manual Operations

```bash
# Reconcile sources (idempotent; starts runtime if needed).
./scripts/executor/sync.sh

# Stop the runtime and re-run sync.
./scripts/executor/restart.sh

# Show runtime + source inventory.
./scripts/executor/status.sh

# Inspect the live control-plane OpenAPI spec.
curl -s http://127.0.0.1:8788/api/docs \
  | python3 -c 'import re,sys,json; m=re.search(r"<script id=\"swagger-spec\" type=\"application/json\">(.*?)</script>",sys.stdin.read(),re.S); print(json.dumps(json.loads(m.group(1)),indent=2))' \
  | jq '.info'

# Tail runtime logs.
tail -f ~/.local/state/executor-mcp-bridges/logs/runtime.log
tail -f ~/Library/Logs/com.kchen.executor-sync.log
```

## Troubleshooting

- `status.sh` is the first stop. It fails fast if the runtime is unreachable.
- Runtime wedged? `restart.sh`. Source state is preserved in SQLite; only the process is replaced.
- If source adds fail right after a version upgrade, inspect `~/.executor` for a
  `executor.jsonc.legacy-*.bak` backup. `sync.sh` rewrites the old object-shaped
  file because Executor `1.4.8` expects `sources` to be an array.
- `executor.jsonc` may stay sparse right after a legacy migration because the
  authoritative catalog already lives in SQLite. A fresh scope or empty catalog
  is rebuilt fully by `sync.sh`.
- Source marked "auth required" or failing to refresh? Check that the
  corresponding env var is actually in the environment (launchd has a minimal
  env — credentials must be in `~/.config/shell/*.sh`).
- GitHub's hosted MCP requires a PAT with the scopes your tools need. No Copilot
  subscription is required; see `github/github-mcp-server` `docs/remote-server.md`.
- Firecrawl's hosted endpoint `https://mcp.firecrawl.dev/v2/mcp` is
  streamable-http; the API key is sent as a Bearer header.
