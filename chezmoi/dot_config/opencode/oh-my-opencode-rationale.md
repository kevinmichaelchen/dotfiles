# Oh-My-OpenCode Model Assignment Rationale

## Overview

This configuration prioritizes **code review quality** while optimizing for
speed where it matters. Models are assigned based on task criticality, with
code-focused tasks using OpenAI's Codex variants and high-throughput tasks using
Cerebras for speed.

## Available Model Tiers

### OpenAI Codex (Code-Optimized)

- **gpt-5.2-codex**: Top-tier reasoning + code optimization
- **gpt-5.1-codex-max**: Strong code capability, maximum at 5.1
- **gpt-5.1-codex-mini**: Lighter, faster, still code-optimized

### OpenAI General

- **gpt-5.2**: Best pure reasoning (non-code-specific)

### Fast Models (Cerebras & MiniMax)

| Model            | SWE-bench                             | Speed      | Cost (in/out) | Use Case                                |
| ---------------- | ------------------------------------- | ---------- | ------------- | --------------------------------------- |
| **GLM 4.7**      | 73.8%                                 | ~1,000 t/s | $2.25/$2.75   | Quality exploration (≈ Haiku 4.5)       |
| **GPT OSS 120B** | 62.4%                                 | ~3,000 t/s | $0.35/$0.75   | Speed-first tasks                       |
| **MiniMax M2.1** | 74% (Verified) / 72.5% (Multilingual) | ~1,500 t/s | $0.30/$1.20   | Multilingual coding & agentic workflows |

**MiniMax M2.1 Advantages:**

- **4.5x faster than GLM 4.7**: 66.9 vs 14.8 tokens/sec
- **2x cheaper**: $0.30/$1.20 vs GLM 4.7's $0.40/$1.50
- **Multilingual excellence**: 72.5% SWE-multilingual (excels in Rust, Java, Go,
  C++, Kotlin)
- **Advanced Interleaved Thinking**: First open-source model with systematic
  problem-solving
- **Agentic performance**: 88.6% VIBE-Bench, excels in full-stack dev

**Note:** Cerebras free tier has a 1M token/day limit. MiniMax M2.1 offers
cost-effective alternative for high-volume use

### Specialized (Google)

- **gemini-3-pro-high**: Strong for creative/visual/UI work
- **gemini-2.5-flash**: Fast multimodal (vision) capability

## Agent Assignments

### Tier 1: Mission Critical (gpt-5.2 / gpt-5.2-codex)

| Agent            | Model                  | Why                                                                   |
| ---------------- | ---------------------- | --------------------------------------------------------------------- |
| `oracle`         | `openai/gpt-5.2`       | Pure reasoning for high-stakes decisions. Not code-specific.          |
| `code-architect` | `openai/gpt-5.2-codex` | Architecture decisions need both strong reasoning AND code expertise. |
| `code-reviewer`  | `openai/gpt-5.2-codex` | **Sacrosanct.** No compromises on catching bugs and security issues.  |

### Tier 2: General Purpose & High-Throughput (MiniMax M2.1)

| Agent     | Model                        | Why                                                                                          |
| --------- | ---------------------------- | -------------------------------------------------------------------------------------------- |
| `general` | `opencode/minimax-m2.1-free` | Cost-effective balance of speed and capability for everyday tasks. 4.5x faster than GLM 4.7. |

### Tier 3: High-Throughput Exploration (MiniMax M2.1)

| Agent           | Model                        | Why                                                                                         |
| --------------- | ---------------------------- | ------------------------------------------------------------------------------------------- |
| `explore`       | `opencode/minimax-m2.1-free` | Speed-focused exploration with better multilingual understanding. 1.5x faster than GLM 4.7. |
| `librarian`     | `opencode/minimax-m2.1-free` | Multilingual doc retrieval with Advanced Interleaved Thinking for complex queries.          |
| `code-explorer` | `cerebras/zai-glm-4.7`       | Understanding code paths needs Haiku-level capability.                                      |

### Tier 4: Specialized Tasks

| Agent                     | Model                       | Why                                                                |
| ------------------------- | --------------------------- | ------------------------------------------------------------------ |
| `document-writer`         | `openai/gpt-5.1-codex-mini` | Docs often include code examples; codex helps, mini keeps it fast. |
| `frontend-ui-ux-engineer` | `google/gemini-3-pro-high`  | Gemini excels at visual reasoning and creative UI/UX tasks.        |
| `multimodal-looker`       | `google/gemini-2.5-flash`   | Vision capability required. Flash is fast and sufficient.          |

## Design Principles

### Code Review is Sacrosanct

The `code-reviewer` agent uses `gpt-5.2-codex`—the absolute best available for
code analysis. Missing a bug or security issue is far more expensive than the
model cost.

### Tiered Exploration Strategy

Not all exploration is equal:

- **`explore`** uses MiniMax M2.1 for fast, multilingual search and pattern
  matching where speed matters most
- **`librarian`** uses MiniMax M2.1 for multilingual retrieval with advanced
  interleaved thinking
- **`code-explorer`** uses GLM 4.7 — deeper reasoning (73.8% SWE-bench) for
  complex code path analysis

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

| Model        | Speed      | Input   | Output  |
| ------------ | ---------- | ------- | ------- |
| GLM 4.7      | ~1,000 t/s | $2.25/M | $2.75/M |
| GPT OSS 120B | ~3,000 t/s | $0.35/M | $0.75/M |

### Free Tier Limits

| Metric      | Limit         |
| ----------- | ------------- |
| Rate Limits | 150K TPM      |
| Daily Limit | 1M tokens/day |

**Warning:** Free tier limit can be hit in ~10 minutes of heavy use. Paid tier
recommended
