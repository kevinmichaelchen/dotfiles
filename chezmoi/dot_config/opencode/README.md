# OpenCode Configuration

Configuration for [OpenCode][opencode], an AI-powered coding assistant.

## Files

| File                         | Purpose                                                        |
| ---------------------------- | -------------------------------------------------------------- |
| `opencode.json`              | Main config: plugins, providers, model definitions             |
| `oh-my-opencode.json`        | [Oh-My-OpenCode][oh-my-opencode] agent model assignments       |
| `oh-my-opencode-rationale.md`| Documentation explaining model assignment decisions            |
| `package.json`               | Plugin dependencies (managed by bun)                           |

## Providers

### Configured Providers

- **[Cerebras][cerebras]** - GLM 4.7 (~1000 tokens/sec)
- **[Google][google-ai]** - Gemini 3 Pro, Gemini 2.5 Flash (via Antigravity)
- **[OpenAI][openai]** - GPT-5.x series (via OAuth/Codex)

### Authentication

Run `/connect` in OpenCode to authenticate with each provider:

```
/connect cerebras    # API key from Cerebras console
/connect google      # OAuth via Antigravity plugin
/connect openai      # OAuth via Codex plugin
```

## Plugins

| Plugin                        | Purpose                                      |
| ----------------------------- | -------------------------------------------- |
| [oh-my-opencode][oh-my-opencode]              | Agent model routing                         |
| [opencode-beads][opencode-beads]              | Task management                             |
| [opencode-openai-codex-auth][codex-auth]      | OpenAI OAuth authentication                 |
| [opencode-anthropic-auth][anthropic-auth]     | Anthropic authentication                    |
| [opencode-antigravity-auth][antigravity-auth] | Google AI via Antigravity                   |

## Model Tiers

See `oh-my-opencode-rationale.md` for detailed reasoning.

| Tier | Use Case                          | Models                                   |
| ---- | --------------------------------- | ---------------------------------------- |
| 1    | Critical architecture decisions   | GPT-5.2, GPT-5.1                         |
| 2    | Code generation & review          | GPT-4.1, Gemini 3 Pro                    |
| 3    | Search & exploration              | GLM 4.7 (OpenCode free)                  |
| 4    | Documentation & structured tasks  | GLM 4.7, Gemini 2.5 Flash                |

### Speed Upgrade: Cerebras Direct API

For ~10-20x faster exploration, switch Tier 3/4 agents to `cerebras/zai-glm-4.7`:

| Metric | OpenCode Free | Cerebras Direct |
|--------|---------------|-----------------|
| Speed  | <100 TPS?     | 1,000-1,700 TPS |
| Cost   | Free          | Free tier available |

See [Cerebras Console][cerebras-console] to get an API key.

## Runtime Files (Not Managed)

These files are generated at runtime and excluded from chezmoi:

- `node_modules/` - Plugin dependencies
- `bun.lock` - Lockfile
- `antigravity-accounts.json` - OAuth tokens (sensitive)
- `.gitignore` - Auto-generated

## Quick Reference

```bash
# Install plugin dependencies
cd ~/.config/opencode && bun install

# List available models
opencode /models

# Connect to a provider
opencode /connect cerebras
```

## References

[opencode]: https://opencode.ai/
[opencode-docs]: https://opencode.ai/docs/
[opencode-providers]: https://opencode.ai/docs/providers/
[oh-my-opencode]: https://github.com/code-yeongyu/oh-my-opencode
[opencode-beads]: https://github.com/opencode-ai/opencode-beads
[codex-auth]: https://github.com/code-yeongyu/opencode-openai-codex-auth
[anthropic-auth]: https://www.npmjs.com/package/opencode-anthropic-auth
[antigravity-auth]: https://www.npmjs.com/package/opencode-antigravity-auth
[cerebras]: https://www.cerebras.ai/
[cerebras-glm]: https://www.cerebras.ai/blog/glm-4-7
[cerebras-console]: https://inference.cerebras.ai/
[google-ai]: https://ai.google.dev/
[openai]: https://platform.openai.com/
