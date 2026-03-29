# OpenCode Configuration

Configuration for [OpenCode][opencode], an AI-powered coding assistant.

## Files

| File                          | Purpose                                                  |
| ----------------------------- | -------------------------------------------------------- |
| `opencode.json`               | Main config: plugins, providers, model definitions       |
| `create_package.json`         | Source manifest for bun-managed plugin dependencies      |

## Providers

### Configured Providers

- **[OpenCode][opencode]** - `mimo-v2-pro-free`, `mimo-v2-omni-free`
- **Fireworks AI** - `accounts/fireworks/routers/kimi-k2p5-turbo`
- **[OpenRouter][openrouter]** - `moonshotai/kimi-k2.5`
- **[OpenAI][openai]** - GPT-5.x series (via OAuth/Codex)

### Authentication

Use `/connect` in OpenCode for OpenAI OAuth:

```
/connect openai      # OAuth via Codex plugin
```

OpenRouter uses `OPENROUTER_API_KEY` from your shell environment. Gemini is
disabled in config and no longer part of this setup. Fireworks AI uses
`FIREWORKS_API_KEY` from your shell environment.

## Defaults

- `model`: `fireworks-ai/accounts/fireworks/routers/kimi-k2p5-turbo`
- `small_model`: `opencode/mimo-v2-omni-free`

## Plugins

| Plugin                                        | Purpose                     |
| --------------------------------------------- | --------------------------- |
| [opencode-openai-codex-auth][codex-auth]      | OpenAI OAuth authentication |

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
```

## References

[opencode]: https://opencode.ai/
[opencode-docs]: https://opencode.ai/docs/
[opencode-providers]: https://opencode.ai/docs/providers/
[openrouter]: https://openrouter.ai/
[codex-auth]: https://github.com/code-yeongyu/opencode-openai-codex-auth
[openai]: https://platform.openai.com/
