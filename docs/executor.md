# Executor

Executor Cloud owns the shared tool catalog, sources, credentials, policies,
workspaces, and execution history. Dotfiles own the CLI declaration in
[mise/config.toml](../mise/config.toml) and the client connection wiring.

## Connect clients

After bootstrap, authenticate the Cloud endpoint in each client:

```bash
codex mcp login executor
opencode mcp auth executor
```

For Claude Code, launch `claude` from a configured shell and authenticate through
`/mcp`. Its declared MCP file loads for the session. Crush uses `mcp-remote`,
which starts its OAuth flow when needed. Each client keeps its own refreshable
session; dotfiles do not distribute bearer tokens.

Desktop connections run `executor mcp` over stdio and need no local HTTP login.
`executor login` is separate: use it when the Executor CLI itself needs hosted
API access.

See [App Settings](../README.md#app-settings) for the managed client files and
how their native config layers load.

## Maintain the catalog

Add or edit sources, secrets, OAuth connections, and policies through Executor's
own UI or CLI. Do not synchronize them from dotfiles or manage
`~/.executor/executor.jsonc` wholesale. That file is an optional plugin manifest,
not the source catalog.

Store hosted source credentials in Executor Cloud. Keep API keys out of committed
environment blocks and source definitions. Local file-based secrets are for
throwaway development, not durable personal tokens.

Keep repo-specific tools, authenticated endpoints, and policy exceptions in
project/workspace scopes rather than global dotfiles.

## Policies

Manage approval rules in Executor Cloud, where the live tool catalog lives:

- Allow clearly read-only tools when repeated prompts add no value.
- Require approval for source configuration, credential binding, OAuth grants,
  secret creation, SQL execution, and paid or durable background jobs.
- Block accidental deletion of sources, connections, and secrets.
- Review policy changes explicitly; use exact tool IDs or narrow families
  instead of copying an aging list of IDs into this repo.

## Troubleshooting

- Repair source authentication in Executor, then reconnect the affected client.
- If an old `executor.jsonc` contains a `sources` key, verify that the live
  catalog has the source before removing the legacy entry.
- Inspect the declared CLI version in Mise rather than relying on a version
  copied into documentation.
