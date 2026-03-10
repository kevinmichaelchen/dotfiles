# Codex MCP Server Overhead

Every MCP server configured in `config.toml` is loaded when Codex starts.
Stdio-based servers spawn subprocesses, and some of those subprocesses
download packages or install dependencies on launch. This adds up.

## Overhead by transport type

| Type | Overhead | Why |
|------|----------|-----|
| **HTTP** (`url = "..."`) | Low (~0s) | Just a URL — no process spawned until first tool call |
| **Stdio** (local binary) | Medium (~1-3s) | Spawns a subprocess (e.g., `mcp-atlassian`) |
| **Stdio** (`npx -y ...`) | Medium-High (~3-10s) | May download the package on first run |
| **Stdio** (`pipx run --no-cache ...`) | High (~10-30s) | Re-installs the package every time |

## Current servers (sorted by overhead)

### Low overhead (HTTP)

| Server | URL |
|--------|-----|
| parallel | `https://search-mcp.parallel.ai/mcp` |
| deepwiki | `https://mcp.deepwiki.com/mcp` |
| grep | `https://mcp.grep.app` |

### Medium overhead (Stdio)

| Server | Command | Notes |
|--------|---------|-------|
| perplexity | `npx -y @perplexity-ai/mcp-server` | Official upstream package |
| exa | `npx -y exa-mcp-server` | Downloads if not cached |
| atlassian | `mcp-atlassian` | Work laptop only |

## Removed servers

### `context7` and `github` (pruned)

These direct MCP entries were removed from Codex's default profile. `github` is
covered well enough by `gh`, and `context7` was retired from the active tool
set.

### `executor` (manual experiment)

Executor remains in the toolchain for experimentation, but it is not wired into
Codex's default MCP profile until its runtime is boring enough to trust as the
primary path.

### `codex` (recursive — removed)

```toml
# REMOVED — do not re-add
[mcp_servers.codex]
command = "codex"
args = ["-m", "gpt-5.2-codex", "mcp-server"]
```

**Problem:** This configured Codex as an MCP server *for itself*. Each Codex
invocation spawned another Codex subprocess, which loaded all the same MCP
servers again — at minimum doubling startup time. In theory, this could recurse
indefinitely (Codex spawns Codex spawns Codex...), though in practice it was
likely bounded by resource limits.

**If you need Codex-as-MCP:** Use it from a *different* agent (e.g., Claude
Code's `.mcp.json`), not from Codex's own config.

## Total startup cost estimate

With all servers loaded:

| Category | Count | Est. time |
|----------|:---:|-----------|
| HTTP servers | 3 | ~0s |
| Stdio (npx) | 2 | ~3-8s |
| Stdio (local binary) | 1 | ~1-2s |
| **Total** | **6** | **~4-10s** |

This overhead applies to every Codex invocation, including when Pliny spawns
Codex for research subtopics.

## Recommendations

1. **Prefer HTTP servers** when available (Parallel, deepwiki, and grep all
   use HTTP directly).
2. **Install stdio servers globally** instead of using `npx -y`.
3. **Never add Codex as its own MCP server** — it causes recursive spawning.
4. **Keep the default profile lean** and avoid re-adding retired MCPs that are
   already covered elsewhere.
