# Executor

Executor Cloud is the shared tool catalog for agent clients on this machine.
Dotfiles manage how clients connect to Executor; Executor owns live runtime
state, hosted sources, credentials, and policies.

This repo pins Executor to `1.4.33`. Executor `1.4.28` was the first local
release where source state is clearly database-owned again. `executor.jsonc` is
an optional plugin manifest, not the source catalog.

## Client Wiring

Codex, OpenCode, and Crush are wired to Executor Cloud as the single global MCP
entry:

- `executor`: `https://executor.sh/mcp`

This repo does not wire agent clients to the local Desktop sidecar. Project-only
or local-only MCPs should live in project/workspace scopes instead of global
dotfiles.

## Ownership

Dotfiles own:

- The pinned Executor CLI version in Mise.
- MCP client wiring for Codex, OpenCode, and Crush.

Executor owns:

- Cloud sources.
- Secrets and OAuth Connections.
- Tool policies.
- Plugins.
- Execution history.
- Workspaces / nested-scope state.

Do not periodically rewrite Executor sources from dotfiles. That turns bash into
a second control plane and fights Executor's own runtime model.

There is intentionally no steady-state source sync script. Add or edit sources,
secrets, OAuth connections, and policies through Executor Cloud.

## Chezmoi Boundary

Chezmoi should manage the pieces that are stable text config:

- agent client wiring that points at the Executor Cloud MCP endpoint
- operator docs

Chezmoi should not own `~/.executor/executor.jsonc` wholesale. Hosted Cloud
configuration belongs to Executor's control plane.

If `doctor.sh` reports a lingering `sources` key in `executor.jsonc`, treat it
as legacy state. Do not port it into dotfiles; verify the live source in
Executor's UI/CLI and remove the stale config entry only after the database copy
is healthy.

## Secrets

Executor source credentials should use Executor secret providers, not committed
env blocks or checked-in source definitions.

| Backend | Use When | Notes |
| --- | --- | --- |
| Executor Cloud / WorkOS Vault | Hosted or shared tools | Preferred for Cloud-connected sources |
| file-secrets | Local throwaway development only | Plain JSON on disk; do not use for durable personal API tokens |

For Cloud sources such as Exa, Parallel, DeepWiki, and Neon, store credentials
in Executor Cloud. The shell API-key templates can remain for non-Executor CLIs,
but Executor sources should not rely on committed env wiring.

## Project Scopes

Global clients use shared Executor endpoints. Project repos should move
project-specific tools and policies into project/workspace scopes instead of
adding them to global dotfiles.

Examples of project-specific sources that should not live in global dotfiles:

- A local Playwright MCP for one app.
- A design MCP only relevant to one UI repo.
- A repo-local state-parks or demo MCP.
- Repo-specific Nia indexes.

## Approval Policy

Executor Cloud's policy model is the right place for tool safety decisions.
Rules are evaluated top-to-bottom. Use exact tool ids for approvals, trailing
wildcards for families, and broad blocks only where the whole namespace is risky.

| Action | Use When |
| --- | --- |
| `always run` | A read-only or low-risk tool is noisy enough that repeated prompts slow work down |
| `require_approval` | A tool should always ask first, even if its source metadata says it is safe |
| `block` | A tool should be hidden from discovery and fail if invoked |

Best practice:

- Keep global Cloud policy permissive only for clearly read-only tools.
- Require approval or block broad write namespaces globally.
- Put project-specific exceptions in project scopes once nested scopes are
  available.
- Let upstream MCP `destructiveHint` annotations require approval by default.

Suggested personal Cloud baseline:

| Pattern | Action | Why |
| --- | --- | --- |
| `executor.coreTools.sources.remove` | `block` | prevents accidental source deletion |
| `executor.coreTools.connections.remove` | `block` | prevents accidental OAuth connection deletion |
| `executor.coreTools.secrets.remove` | `block` | prevents accidental secret deletion |
| `parallel_api.monitor.cancelMonitorV1MonitorsMonitorIdCancelPost` | `block` | irreversible monitor cancellation |
| `executor.coreTools.policies.*` | `require_approval` | policy edits change the safety boundary |
| `executor.coreTools.sources.configure` | `require_approval` | source edits can redirect tools or credentials |
| `executor.coreTools.sources.bindings.*` | `require_approval` | credential binding edits affect auth behavior |
| `executor.*.addSource` | `require_approval` | adding tools changes the available capability set |
| `executor.*.configureSource` | `require_approval` | source configuration can change auth and endpoints |
| `executor.coreTools.secrets.create` | `require_approval` | secret creation should stay intentional |
| `executor.coreTools.oauth.start` | `require_approval` | OAuth grants should stay intentional |
| `neon_mcp.run_sql` | `require_approval` | SQL can mutate data depending on the statement |
| `neon_mcp.run_sql_transaction` | `require_approval` | SQL transactions can mutate data |
| `neon_mcp.get_connection_string` | `require_approval` | exposes sensitive database connection material |
| `neon_mcp.get_neon_auth_config` | `require_approval` | exposes auth configuration |
| `neon_mcp.list_slow_queries` | `require_approval` | can reveal sensitive SQL text |
| `parallel_api.monitor.createMonitorV1MonitorsPost` | `require_approval` | creates durable monitoring state |
| `parallel_api.monitor.updateMonitorV1MonitorsMonitorIdUpdatePost` | `require_approval` | changes durable monitoring state |
| `parallel_api.monitor.triggerMonitorRunV1MonitorsMonitorIdTriggerPost` | `require_approval` | triggers an out-of-band run |
| `parallel_api.findAll.ingestFindallRunV1betaFindallIngestPost` | `require_approval` | creates ingestion work |
| `parallel_api.tasks.tasksRunsPostV1TasksRunsPost` | `require_approval` | starts paid/async task execution |
| `parallel_api.tasks.tasksTaskgroupsPostV1TasksGroupsPost` | `require_approval` | creates task groups |
| `parallel_api.tasks.tasksTaskgroupsRunsPostV1TasksGroupsTaskgroupIdRunsPost` | `require_approval` | starts task-group runs |
| `exa_search_api.research.researchTasksCreate` | `require_approval` | creates async research work |
| `deepwiki_mcp.*` | `always run` | read-only repository documentation lookups |
| `exa_search_api.search.postOperation` | `always run` | read-only search |
| `exa_search_api.answer.postOperation` | `always run` | read-only answer/search flow |
| `exa_search_api.research.researchControllerV0GetResearchTask` | `always run` | read-only task lookup |
| `exa_search_api.research.researchTasksList` | `always run` | read-only task listing |
| `parallel_api.search.v1SearchV1SearchPost` | `always run` | read-only web search |
| `parallel_api.monitor.listMonitorsV1MonitorsGet` | `always run` | read-only monitor listing |
| `neon_mcp.list_docs_resources` | `always run` | read-only docs index |
| `neon_mcp.get_doc_resource` | `always run` | read-only docs fetch |
| `neon_mcp.search` | `always run` | read-only account/project search |
| `neon_mcp.list_organizations` | `always run` | read-only inventory |
| `neon_mcp.list_projects` | `always run` | read-only inventory |
| `neon_mcp.list_shared_projects` | `always run` | read-only inventory |
| `neon_mcp.describe_project` | `always run` | read-only inspection |
| `neon_mcp.describe_branch` | `always run` | read-only inspection |
| `neon_mcp.describe_table_schema` | `always run` | read-only schema inspection |
| `neon_mcp.get_database_tables` | `always run` | read-only schema inventory |
| `neon_mcp.list_branch_computes` | `always run` | read-only compute inventory |
| `neon_mcp.compare_database_schema` | `always run` | read-only schema comparison |
| `neon_mcp.explain_sql_statement` | `always run` | read-only SQL explanation |
| `neon_mcp.fetch` | `always run` | read-only fetch by id |

## Manual Operations

```bash
npx add-mcp https://executor.sh/mcp --transport http --name executor
```

## Troubleshooting

- Source auth broken? Fix it in Executor Cloud, not in dotfiles.
- Project-only MCPs should live in project/workspace scopes.
