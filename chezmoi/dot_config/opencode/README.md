# OpenCode Configuration

Configuration for [OpenCode][opencode], an AI-powered coding assistant.

## Files

| File                                   | Purpose                                             |
| -------------------------------------- | --------------------------------------------------- |
| `modify_private_opencode.json.tmpl`    | Merges Executor MCP entries and the model catalog   |
| `create_package.json`                  | Source manifest for bun-managed plugin dependencies |
| `command/tokenscope.md`                | `/tokenscope` command prompt for TokenScope reports |

### What Chezmoi owns

`modify_private_opencode.json.tmpl` rewrites only part of
`~/.config/opencode/opencode.json` and passes the rest through untouched.

| Key                        | Owner          |
| -------------------------- | -------------- |
| `mcp.executor{,-desktop}`  | Chezmoi        |
| `provider.*`               | Chezmoi        |
| `model`, `small_model`     | Machine-local  |
| `plugin`, everything else  | Machine-local  |

`model` and `small_model` are deliberately unmanaged so switching models in the
TUI is not reverted on the next `chezmoi apply`.

### Authentication

Credentials never live in this repository. Authenticate each provider once per
machine; OpenCode stores the result in `~/.local/share/opencode/auth.json`.

```bash
opencode providers        # add or inspect provider credentials (alias: auth)
opencode mcp auth executor  # OAuth for the Executor Cloud MCP endpoint
```

Executor Desktop runs locally over `executor mcp` stdio and needs no token.

## Models

The catalog declares entries that the upstream [models.dev][modelsdev] catalog
does not provide on its own:

| Provider     | Entries                                     | Why declared                           |
| ------------ | ------------------------------------------- | -------------------------------------- |
| `openai`     | `gpt-5.5`, `gpt-5.2{,-codex}` effort splits | models.dev ships base models only      |
| `openrouter` | `moonshotai/kimi-k2.6`                       | `data_collection: deny` routing        |
| `openrouter` | `deepseek/deepseek-v4-pro-0813`              | dated checkpoint + routing             |
| `openrouter` | `deepseek/deepseek-v4-flash-0731`            | dated checkpoint + routing             |

Everything else resolves from the built-in models.dev catalog.

## Plugins

| Plugin                                       | Purpose                      |
| -------------------------------------------- | ---------------------------- |
| [opencode-openai-codex-auth][codex-auth]     | OpenAI OAuth authentication  |
| [@ramtinj95/opencode-tokenscope][tokenscope] | Token usage and cost reports |

`create_package.json` uses Chezmoi's `create_` prefix: the target is written
only when it does not already exist, so `bun install` may rewrite it freely.
The trade-off is that bumping a version here reaches new machines only. Update
an existing machine by hand:

```bash
cd ~/.config/opencode && bun install
```

## Runtime Files (Not Managed)

Generated at runtime and excluded from Chezmoi via `.chezmoiignore`:

- `node_modules/` - Plugin dependencies
- `bun.lock` - Lockfile
- `.gitignore` - Auto-generated
- `skills/` - Symlinks into `~/.agents/skills`

## Quick Reference

```bash
# Install plugin dependencies
cd ~/.config/opencode && bun install

# List available models, optionally for one provider
opencode models
opencode models openrouter

# Manage provider credentials
opencode providers

# Run a one-off prompt against a specific model
opencode run -m openrouter/deepseek/deepseek-v4-flash-0731 "..."
```

`/tokenscope` is a TUI slash command; run it from inside `opencode`, not the
shell.

## References

[opencode]: https://opencode.ai/
[opencode-docs]: https://opencode.ai/docs/
[opencode-providers]: https://opencode.ai/docs/providers/
[modelsdev]: https://models.dev/
[codex-auth]: https://github.com/code-yeongyu/opencode-openai-codex-auth
[tokenscope]: https://github.com/ramtinJ95/opencode-tokenscope
