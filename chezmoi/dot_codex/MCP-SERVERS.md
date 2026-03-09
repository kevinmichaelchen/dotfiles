# Codex MCP Server Overhead

Every MCP server configured in `config.toml` is loaded when Codex starts.
Stdio-based servers spawn subprocesses, and some of those subprocesses
download packages or install dependencies on launch. This adds up.

## Overhead by transport type

| Type | Overhead | Why |
|------|----------|-----|
| **HTTP** (`url = "..."`) | Low (~0s) | Just a URL — no process spawned until first tool call |
| **Stdio** (local binary) | Medium (~1-3s) | Spawns a subprocess (e.g., `perplexity-mcp`) |
| **Stdio** (`npx -y ...`) | Medium-High (~3-10s) | May download the package on first run |
| **Stdio** (`pipx run --no-cache ...`) | High (~10-30s) | Re-installs the package every time |

## Current servers (sorted by overhead)

### Low overhead (HTTP)

| Server | URL |
|--------|-----|
| parallel | `https://search-mcp.parallel.ai/mcp` |
| context7 | `https://mcp.context7.com/mcp` |
| deepwiki | `https://mcp.deepwiki.com/mcp` |
| github | `https://api.githubcopilot.com/mcp/` |
| grep | `https://mcp.grep.app` |

### Medium overhead (Stdio)

| Server | Command | Notes |
|--------|---------|-------|
| perplexity | `perplexity-mcp` | Local binary, fast |
| exa | `npx -y exa-mcp-server` | Downloads if not cached |
| atlassian | `mcp-atlassian` | Work laptop only |

## Removed servers

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
| HTTP servers | 5 | ~0s |
| Stdio (local binary) | 1 | ~1-2s |
| Stdio (npx) | 1 | ~2-5s |
| **Total** | **7** | **~3-7s** |

This overhead applies to every Codex invocation, including when Pliny spawns
Codex for research subtopics.

## Recommendations

1. **Prefer HTTP servers** when available (context7, deepwiki, github, grep
   all offer HTTP endpoints).
2. **Install stdio servers globally** instead of using `npx -y`.
3. **Never add Codex as its own MCP server** — it causes recursive spawning.
4. **Consider a lighter profile** for automated/scripted usage (e.g., Pliny)
   with fewer MCP servers.
