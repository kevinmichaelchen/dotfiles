# Executor

Executor is the local execution layer for shared agent tooling in this repo.
Codex and Claude talk to one local MCP endpoint:

- `http://127.0.0.1:8788/mcp`

That endpoint is backed by a local Executor daemon plus a sync script that
registers the actual tools and API sources.

## Architecture

| Component | Role |
| --- | --- |
| Codex / Claude | MCP clients that call Executor |
| Executor daemon | Local tool catalog and execution runtime |
| `scripts/executor-launchd-sync.sh` | Rebuilds shell env for background runs |
| `scripts/executor-sync-mcp.sh` | Reconciles sources into Executor |
| `supergateway` | Converts stdio MCP servers into local HTTP MCP endpoints |
| `tmux` | Keeps bridge processes alive between calls |
| LaunchAgent | Starts sync on login and every 15 minutes |

## Source Types

Executor currently manages three source shapes:

1. Direct remote MCP sources
   - Example: DeepWiki, grep
2. OpenAPI sources
   - Example: Executor Control Plane, Perplexity Search, Parallel Search
3. Local stdio MCP sources behind a bridge
   - Example: GitHub, Exa, Atlassian, Hugging Face, Effect docs, Nia, Firecrawl

Only the third category needs the bridge layer.

## Startup Flow

1. macOS launchd loads `com.kchen.executor-sync`.
2. The LaunchAgent runs `scripts/executor-launchd-sync.sh`.
3. That script reconstructs `PATH`, activates Mise, and sources secret-backed shell modules like `github.sh`, `perplexity.sh`, and `jira.sh`.
4. It then execs `scripts/executor-sync-mcp.sh`.
5. The sync script ensures the local Executor daemon is reachable.
6. It registers the local Executor control plane as an OpenAPI source when `/v1/openapi.json` is available.
7. It starts helper processes for any stdio-backed MCP servers and the local OpenAPI spec server.
8. It registers direct MCP, OpenAPI, and bridged MCP endpoints into the current Executor workspace.

## v1.2 Features In Use

This repo now leans on two Executor `v1.2.x` changes:

- Executor separates shareable source definitions from actor-scoped auth material. The sync script reconciles stable source definitions while leaving auth material local for sources like Perplexity Search and Parallel Search.
- Executor exposes its control-plane OpenAPI spec at `/v1/openapi.json`. The sync script registers that spec as the `executor_control` OpenAPI source.

That makes the local control plane self-describing: the same tool catalog that exposes GitHub, Firecrawl, or Perplexity can also expose Executor's own workspace and source APIs.

## What "tmux/launchd-managed bridge" Means

This repo uses that phrase to describe the local plumbing around stdio MCP
servers.

For a stdio-only MCP server like `github-mcp-server`:

1. `supergateway` launches the stdio server and exposes it locally as HTTP MCP.
2. The HTTP endpoint lives on `127.0.0.1:<port>/mcp`.
3. The bridge process is run inside a detached `tmux` session so it stays alive.
4. Executor registers that local HTTP endpoint as a normal MCP source.

That is the "bridge":

- stdio MCP server -> `supergateway` -> local HTTP MCP endpoint -> Executor source

`tmux` is used as lightweight process supervision.
`launchd` is used to kick off the sync automatically after login.

## Why This Exists

Without Executor, each client would carry and start its own MCP graph.

With Executor:

- Codex and Claude see one shared tool catalog
- source auth and runtime state are centralized locally
- OpenAPI APIs and MCP servers live behind one control plane
- the control plane can describe itself as a normal OpenAPI source
- clients avoid duplicating MCP configuration

## Current Managed Sources

The source inventory is defined in `scripts/executor-sync-mcp.sh`.

At a high level it includes:

- Executor Control Plane
- DeepWiki
- grep
- GitHub
- Exa
- Atlassian
- Hugging Face
- Effect docs
- Nia
- Firecrawl
- Perplexity Search
- Parallel Search

## Manual Operations

```bash
# Reconcile Executor sources manually
./scripts/executor-sync-mcp.sh

# Run the launchd-style sync path manually
./scripts/executor-launchd-sync.sh

# Check Executor health
executor doctor --json

# Inspect the local control-plane OpenAPI document
curl -s http://127.0.0.1:8788/v1/openapi.json | jq '.info'

# Inspect running bridge logs
tail -f ~/.local/state/executor-mcp-bridges/logs/github.log
tail -f ~/Library/Logs/com.kchen.executor-sync.log
```

## Troubleshooting

If a bridged source behaves incorrectly, check these in order:

1. `executor doctor --json`
2. `~/.local/state/executor-mcp-bridges/logs/<source>.log`
3. `~/Library/Logs/com.kchen.executor-sync.log`
4. whether the required env vars are present in the sourced shell module

One subtlety: `tmux` can retain stale environment variables. The sync script now
refreshes secret-backed env vars in the tmux server before starting bridge
sessions.
