# OpenCode Configuration

Configuration for [OpenCode][opencode], an AI-powered coding assistant.

## Files

| File                                   | Purpose                                             |
| -------------------------------------- | --------------------------------------------------- |
| `dotfiles/.config/opencode/dotfiles.json`    | Merges Executor MCP entries and the model catalog   |
| `plugin` declarations | Native plugin package declarations |
| `command/tokenscope.md`                | `/tokenscope` command prompt for TokenScope reports |

### Native config layers

`dotfiles/.config/opencode/dotfiles.json` is loaded through `OPENCODE_CONFIG` after the machine-local
`~/.config/opencode/opencode.json`. OpenCode merges the layers itself.

| Key                        | Owner          |
| -------------------------- | -------------- |
| `mcp.executor{,-desktop}`  | Managed layer |
| `provider.openai.options`, `provider.openrouter.models` | Managed layer |
| `small_model`              | Managed layer |
| `model`                    | Machine-local  |
| `plugin`, everything else  | Machine-local  |

`model` is deliberately unmanaged so switching the primary model in the TUI is
not reverted on the next `mise bootstrap`. `small_model` is kept on DeepSeek
V4.1 Flash so lightweight background work does not fall back to a stale model.

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
| `openai`     | OpenCode's current provider catalog           | provider-wide reasoning/privacy defaults |
| `openrouter` | `moonshotai/kimi-k3`                          | current Kimi flagship + privacy routing |
| `openrouter` | `deepseek/deepseek-v4.1-flash`                | current efficient DeepSeek flagship     |

Everything else resolves from the built-in models.dev catalog.

## Plugins

| Plugin                                       | Purpose                      |
| -------------------------------------------- | ---------------------------- |
| [opencode-openai-codex-auth][codex-auth]     | OpenAI OAuth authentication  |
| [@ramtinj95/opencode-tokenscope][tokenscope] | Token usage and cost reports |

The managed config declares plugin package names and versions in `plugin`;
OpenCode merges plugin declarations by identity and handles installation. The
existing `package.json` and plugin choices remain local, and no dependency seed
is written during bootstrap.

## Runtime Files (Not Managed)

Generated at runtime and left unmanaged by Mise:

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
opencode run -m openrouter/deepseek/deepseek-v4.1-flash "..."
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
