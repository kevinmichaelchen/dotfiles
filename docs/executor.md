# Executor

Executor Cloud owns the shared tool catalog, sources, credentials, policies,
workspaces, and execution history. Dotfiles own the CLI declaration in
[mise/config.toml](../mise/config.toml); each harness reaches Executor through
its own plugin, connector, or MCP layer.

## Connect clients

Codex needs no entry in `~/.codex/config.toml`. Enable the
`executor@openai-curated-remote` plugin once from the Codex plugin marketplace:

```bash
codex plugin add executor@openai-curated-remote
```

The plugin contributes the hosted `https://mcp.executor.sh/mcp` server and its
skill, so sessions see `mcp__codex_apps__executor`.

OpenCode has no connector store, so the shared override layer declares that same
hosted server and each machine authenticates it once:

```bash
opencode mcp auth executor
```

For Claude Code there is nothing to wire: the account connector registered in
the Claude account already supplies Executor, so no `~/.claude.json` entry and no
`--mcp-config` file are needed, and every machine shares one connection. Open
`/mcp` in a session only to check or re-authenticate the connector.

No client registers `executor mcp` over stdio by default. `executor login` is
separate: use it when the Executor CLI itself needs hosted API access.

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
