# Oh-My-OpenCode Model Assignment Rationale

## Overview

This configuration prioritizes **code review quality** while optimizing for
speed where it matters. Models are assigned based on task criticality, with
code-focused tasks using OpenAI's Codex variants and high-throughput tasks
using Cerebras for speed.

## Available Model Tiers

### OpenAI Codex (Code-Optimized)

- **gpt-5.2-codex**: Top-tier reasoning + code optimization
- **gpt-5.1-codex-max**: Strong code capability, maximum at 5.1
- **gpt-5.1-codex-mini**: Lighter, faster, still code-optimized

### OpenAI General

- **gpt-5.2**: Best pure reasoning (non-code-specific)

### Fast Models (Cerebras)

| Model | SWE-bench | Speed | Cost (in/out) | Use Case |
|-------|-----------|-------|---------------|----------|
| **GLM 4.7** | 73.8% | ~1,000 t/s | $2.25/$2.75 | Quality exploration (≈ Haiku 4.5) |
| **GPT OSS 120B** | 62.4% | ~3,000 t/s | $0.35/$0.75 | Speed-first tasks |

**Note:** Cerebras free tier has a 1M token/day limit. Paid tier recommended for heavy use

### Specialized (Google)

- **gemini-3-pro-high**: Strong for creative/visual/UI work
- **gemini-2.5-flash**: Fast multimodal (vision) capability

## Agent Assignments

### Tier 1: Mission Critical (gpt-5.2 / gpt-5.2-codex)

| Agent            | Model                  | Why                                                                    |
| ---------------- | ---------------------- | ---------------------------------------------------------------------- |
| `oracle`         | `openai/gpt-5.2`       | Pure reasoning for high-stakes decisions. Not code-specific.           |
| `code-architect` | `openai/gpt-5.2-codex` | Architecture decisions need both strong reasoning AND code expertise.  |
| `code-reviewer`  | `openai/gpt-5.2-codex` | **Sacrosanct.** No compromises on catching bugs and security issues.   |

### Tier 2: General Purpose (gpt-5.2)

| Agent     | Model            | Why                                                         |
| --------- | ---------------- | ----------------------------------------------------------- |
| `general` | `openai/gpt-5.2` | Balanced capability for everyday tasks. Best general model. |

### Tier 3: High-Throughput Exploration (Cerebras)

| Agent           | Model                   | Why                                                                     |
| --------------- | ----------------------- | ----------------------------------------------------------------------- |
| `explore`       | `cerebras/gpt-oss-120b` | Pure file search/pattern matching. 3x faster, 6x cheaper. Speed > quality. |
| `librarian`     | `cerebras/zai-glm-4.7`  | Retrieval needs understanding. GLM 4.7 ≈ Haiku 4.5 quality.             |
| `code-explorer` | `cerebras/zai-glm-4.7`  | Understanding code paths needs Haiku-level capability.                  |

### Tier 4: Specialized Tasks

| Agent                     | Model                      | Why                                                              |
| ------------------------- | -------------------------- | ---------------------------------------------------------------- |
| `document-writer`         | `openai/gpt-5.1-codex-mini`| Docs often include code examples; codex helps, mini keeps it fast.|
| `frontend-ui-ux-engineer` | `google/gemini-3-pro-high` | Gemini excels at visual reasoning and creative UI/UX tasks.      |
| `multimodal-looker`       | `google/gemini-2.5-flash`  | Vision capability required. Flash is fast and sufficient.        |

## Design Principles

### Code Review is Sacrosanct

The `code-reviewer` agent uses `gpt-5.2-codex`—the absolute best available for
code analysis. Missing a bug or security issue is far more expensive than the
model cost.

### Tiered Cerebras Strategy

Not all exploration is equal:

- **`explore`** uses GPT OSS 120B (3x faster, 6x cheaper) — pure file search
  and pattern matching where speed matters most
- **`librarian`** and **`code-explorer`** use GLM 4.7 — these need Haiku-level
  understanding (73.8% SWE-bench) to properly analyze code and retrieve context

If you hit something truly complex, escalate to `oracle` or `code-architect`.

### Codex for Code, General for Reasoning

- Use `-codex` variants for tasks involving code generation, review, or analysis
- Use non-codex `gpt-5.2` for pure reasoning tasks (oracle, general)

### Gemini for Visual/Creative Work

Google's Gemini models excel at visual and creative tasks. Use them where those
strengths matter (UI/UX, multimodal).

## Cerebras Setup

Cerebras provides ~10-20x speed boost over hosted alternatives.

**To enable Cerebras:**
1. Get API key at https://cloud.cerebras.ai
2. Run `/connect cerebras` in OpenCode

### Pricing

| Model | Speed | Input | Output |
|-------|-------|-------|--------|
| GLM 4.7 | ~1,000 t/s | $2.25/M | $2.75/M |
| GPT OSS 120B | ~3,000 t/s | $0.35/M | $0.75/M |

### Free Tier Limits

| Metric      | Limit |
| ----------- | ----- |
| Rate Limits | 150K TPM |
| Daily Limit | 1M tokens/day |

**Warning:** Free tier limit can be hit in ~10 minutes of heavy use. Paid tier recommended
