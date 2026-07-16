# OpenCode Configuration

Configuration for [OpenCode][opencode], an AI-powered coding assistant.

## Files

| File                          | Purpose                                                  |
| ----------------------------- | -------------------------------------------------------- |
| `create_package.json`         | Source manifest for bun-managed plugin dependencies      |
| `command/tokenscope.md`       | `/tokenscope` command prompt for TokenScope reports       |

### Authentication

Use `/connect` in OpenCode for provider-owned authentication. For example:

```
/connect openai      # OAuth via Codex plugin
```

Chezmoi manages only the two Executor MCP entries. Executor Cloud uses
OpenCode's OAuth flow (`opencode mcp auth executor`), and Executor Desktop runs
locally through `executor mcp` over stdio. Other provider authentication belongs
to OpenCode's `/connect` flow.

## Plugins

| Plugin                                        | Purpose                     |
| --------------------------------------------- | --------------------------- |
| [opencode-openai-codex-auth][codex-auth]      | OpenAI OAuth authentication |
| [@ramtinj95/opencode-tokenscope][tokenscope]  | Token usage and cost reports |

## Runtime Files (Not Managed)

These files are generated at runtime and excluded from chezmoi:

- `node_modules/` - Plugin dependencies
- `bun.lock` - Lockfile
- `.gitignore` - Auto-generated

## Quick Reference

```bash
# Install plugin dependencies
cd ~/.config/opencode && bun install

# List available models
opencode /models

# Connect to a provider
opencode /connect openai

# Analyze token usage for the current session
opencode /tokenscope
```

## References

[opencode]: https://opencode.ai/
[opencode-docs]: https://opencode.ai/docs/
[opencode-providers]: https://opencode.ai/docs/providers/
[codex-auth]: https://github.com/code-yeongyu/opencode-openai-codex-auth
[tokenscope]: https://github.com/ramtinJ95/opencode-tokenscope
