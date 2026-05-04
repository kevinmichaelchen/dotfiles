# Executor vs Docker MCP Catalog

A comparison of two approaches to managing MCP tool infrastructure for AI
agents: [Executor][executor], a local-first control plane that aggregates MCP,
OpenAPI, and GraphQL sources, and the [Docker MCP Catalog][docker-mcp], which
runs MCP servers as sandboxed Docker containers behind a gateway.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Feature Comparison](#feature-comparison)
- [Source and Tool Management](#source-and-tool-management)
- [Sandboxing](#sandboxing)
- [When to Use Which](#when-to-use-which)
- [Complementary Usage](#complementary-usage)
- [Licensing and Pricing](#licensing-and-pricing)
- [Limitations](#limitations)

## Overview

|                  | **Executor**                                                                                               | **Docker MCP Catalog**                                                                  |
| ---------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Creator          | [Rhys Sullivan][executor] (open source)                                                                    | [Docker Inc.][docker-mcp]                                                               |
| Core idea        | Local daemon + control plane that aggregates MCP, OpenAPI, and GraphQL sources into a unified tool catalog | Docker Desktop extension that runs MCP servers as sandboxed containers behind a gateway |
| Primary strength | Tool aggregation across heterogeneous source types                                                         | Sandboxed, governed MCP server lifecycle management                                     |
| Dependencies     | Bun, Effect (TypeScript)                                                                                   | Docker Desktop 4.48+                                                                    |

## Architecture

### Executor

Executor runs a single daemon on `localhost:8788` with a layered architecture:

| Layer        | Component                          | Role                                                                               |
| ------------ | ---------------------------------- | ---------------------------------------------------------------------------------- |
| CLI          | `executor daemon`, `executor tools`, `executor call`, `executor resume`, `executor mcp` | Daemon lifecycle, discovery, invocation, and MCP serving |
| Server       | Local HTTP server                  | Serves API (`/v1`), MCP endpoint (`/mcp`), and web UI                              |
| Platform SDK | Core business logic                | Source discovery, auth, tool indexing, execution tracking                          |
| Sandbox      | QuickJS WASM                       | Executes agent TypeScript in isolation; tool calls proxy through the control plane |

All sources, secrets, policies, and execution history live in a single local
workspace shared across the CLI, web UI, and MCP clients. The daemon
auto-provisions an account, organization, and workspace on first start — zero
manual setup.

### Docker MCP Catalog

Docker MCP runs three components inside Docker Desktop:

| Component       | Role                                                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **MCP Catalog** | 300+ verified MCP servers packaged as container images on Docker Hub                                                            |
| **MCP Gateway** | Centralized proxy that routes tool requests, launches containers on demand, injects credentials, and enforces security policies |
| **Profiles**    | Named collections of MCP servers organized by project or workflow                                                               |

The Gateway starts automatically with Docker Desktop. Clients connect to the
Gateway rather than to individual servers.

## Feature Comparison

| Dimension            | **Executor**                                              | **Docker MCP**                                        |
| -------------------- | --------------------------------------------------------- | ----------------------------------------------------- |
| Source types         | MCP + OpenAPI + GraphQL                                   | MCP only                                              |
| Sandboxing           | QuickJS WASM (code-level)                                 | Docker containers (process-level)                     |
| Discovery            | Intent-based search across all sources                    | Browse a curated catalog of 300+ servers              |
| Tool aggregation     | Single MCP endpoint exposes all sources                   | Gateway routes to individual containers               |
| Config sharing       | Workspace files                                           | Profiles, shareable across clients and teams          |
| Web UI               | Yes — browse tools, sources, secrets                      | Docker Desktop UI                                     |
| Human-in-the-loop    | Built-in: OAuth flows, approval pauses, `executor resume` | Manual credential setup via `docker mcp secret set`   |
| Governance           | Nascent policy infrastructure                             | Built-in logging, call-tracing, custom catalogs       |
| OpenAPI bridging     | First-class — point at a spec, get typed tools            | Not supported natively                                |
| Multi-client support | Exposes itself as a single MCP server for any client      | Gateway supports Claude Code, Cursor, Zed, and others |

## Source and Tool Management

### Executor

Executor normalizes three source types into a unified tool catalog:

| Source Type  | How It Works                                                                       |
| ------------ | ---------------------------------------------------------------------------------- |
| MCP servers  | Remote MCP endpoints via HTTP/SSE transport                                        |
| OpenAPI APIs | REST endpoints described by OpenAPI specs, auto-converted to typed tool operations |
| GraphQL      | Introspectable GraphQL services converted to callable tools                        |

The source lifecycle follows a consistent flow: **discovery** (auto-detect
source type from a URL) → **connection and auth** (bearer, OAuth redirect, or
none) → **tool indexing** (transform into workspace-visible tools with schemas)
→ **inspection** (browsable metadata in the web UI).

Agents use `tools.discover()` to search tools by intent and
`tools.describe.tool()` to inspect schemas, rather than receiving a massive
manifest upfront.

### Docker MCP Catalog

Docker manages MCP servers exclusively:

| Step           | How It Works                                                                    |
| -------------- | ------------------------------------------------------------------------------- |
| Browse catalog | 300+ verified servers on Docker Hub with versioning and provenance tracking     |
| Configure      | `docker mcp secret set` and `docker mcp config set` for centralized credentials |
| Launch         | Gateway starts containers on demand when a tool is requested                    |
| Organize       | Profiles group servers by project; custom catalogs restrict to approved servers |

Organizations can create custom catalogs containing only their approved servers,
which is useful for governance in enterprise settings.

## Sandboxing

The two tools take fundamentally different approaches to isolation:

| Aspect            | **Executor**                                                              | **Docker MCP**                                                          |
| ----------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Isolation model   | WASM-based QuickJS sandbox for agent code execution                       | Docker containers with restricted privileges, network, and resources    |
| Scope             | Isolates the _agent's code_ — tool calls proxy through the control plane  | Isolates each _MCP server process_ from the host and from other servers |
| Overhead          | Lightweight (in-process WASM)                                             | Heavier (container per server)                                          |
| Security boundary | Code cannot make direct network calls; everything routes through Executor | Process-level isolation with Linux namespaces and cgroups               |

## When to Use Which

**Executor is the better fit when you:**

- Need to aggregate OpenAPI and GraphQL alongside MCP — this is its killer
  feature
- Want a lightweight local daemon without the Docker Desktop dependency
- Prefer intent-based tool discovery over manual per-server configuration
- Need human-in-the-loop execution flows with durable pause/resume

**Docker MCP is the better fit when you:**

- Want strong process-level container sandboxing for untrusted MCP servers
- Prefer a large, curated catalog of pre-built, verified servers
- Need team-wide governance with logging, call-tracing, and custom catalogs
- Already run Docker Desktop and want near-zero-config MCP setup

## Complementary Usage

These tools are not mutually exclusive. You can run MCP servers via Docker MCP
and register them as MCP sources in Executor. This gives you:

- Docker's container-level sandboxing and catalog for individual MCP servers
- Executor's aggregation layer to unify those servers with OpenAPI and GraphQL
  sources behind a single MCP endpoint
- Intent-based discovery across all source types from any AI client

## Licensing and Pricing

|                  | **Executor**                        | **Docker MCP**                                                                                                                              |
| ---------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| License          | [MIT][executor] (fully open source) | Bundled with [Docker Desktop][docker-desktop-pricing] (closed source)                                                                       |
| Cost             | Free                                | Free for personal use, education, and small businesses (<250 employees, <$10M revenue); paid subscription required for larger organizations |
| Cloud dependency | None — local-first, local-only      | None — runs locally via Docker Desktop                                                                                                      |

## Limitations

### Executor

- **Early-stage**: Third architecture iteration; `legacy/` and `legacy2/`
  directories remain in the repo
- **Small community**: Minimal issue tracker activity suggests early adoption
- **Local-only**: No multi-machine sync or cloud backend (service boundaries
  exist for future support)
- **Bun-dependent**: Uses Bun as both package manager and dev runtime
- **Effect learning curve**: The entire codebase is built on the
  [Effect][effect] TypeScript library, which can be challenging for contributors

### Docker MCP

- **Heavy dependency**: Requires Docker Desktop 4.48+ running at all times
- **MCP only**: No native support for OpenAPI or GraphQL sources
- **Container overhead**: Each server runs as a full Docker container
- **Closed source**: The predecessor open-source repo
  ([docker/labs-ai-tools-for-devs][docker-labs]) is deprecated in favor of the
  integrated toolkit
- **Gateway is a single point of failure**: If Docker Desktop is not running, no
  MCP servers are available
- **Catalog is curated, not exhaustive**: 300+ servers may not cover niche or
  custom use cases (though custom catalogs help)

[executor]: https://github.com/RhysSullivan/executor
[docker-mcp]: https://charm.land/blog/crush-and-docker-mcp/
[docker-desktop-pricing]: https://www.docker.com/pricing/
[docker-labs]: https://github.com/docker/labs-ai-tools-for-devs
[effect]: https://effect.website
