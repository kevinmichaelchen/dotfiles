# Oh-My-OpenCode Model Assignment Rationale

## Overview

This configuration optimizes cost-effectiveness while maintaining high-quality
output by allocating models based on task complexity, frequency, and required
capabilities. Anthropic models are avoided in favor of OpenAI, Google, and
Cerebras.

## Available Model Tiers

### Paid Models (Subscription-based)

- **OpenAI**: GPT-5.2, GPT-5.1, GPT-4.1
- **Google**: Gemini 3 Pro, Gemini 2.5 Flash

### Fast Models (Cerebras)

- **Cerebras**: zai-glm-4.7 (~1,000-1,700 tokens/sec)

## Agent Assignments

### Tier 1: Critical Reasoning & Architecture (High Cost, Low Frequency)

| Agent            | Model            | Why                                                                                                                           |
| ---------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `oracle`         | `openai/gpt-5.2` | Best available reasoning for high-impact architecture decisions. Used sparingly (~5-10% of tasks), so cost impact is minimal. |
| `code-architect` | `openai/gpt-5.1` | Strong at comprehensive blueprint generation and implementation planning.                                                     |

### Tier 2: High-Quality Code & Analysis (Mid-High Cost, Medium Frequency)

| Agent                     | Model                      | Why                                                                                                   |
| ------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------- |
| `general`                 | `openai/gpt-4.1`           | Balanced capability for most coding tasks. Good sweet spot of quality vs cost.                        |
| `code-explorer`           | `openai/gpt-4.1`           | Deep codebase analysis requires strong reasoning to trace execution paths and map architecture.       |
| `code-reviewer`           | `openai/gpt-4.1`           | Bug detection, security analysis, and quality assessment benefit from strong analytical capabilities. |
| `frontend-ui-ux-engineer` | `google/gemini-3-pro-high` | Gemini 3 excels at visual reasoning and UI/UX tasks. Optimized for design and layout decisions.       |

### Tier 3: High-Frequency Search & Retrieval (Fast, High Frequency)

| Agent       | Model                  | Why                                                                                                 |
| ----------- | ---------------------- | --------------------------------------------------------------------------------------------------- |
| `explore`   | `cerebras/zai-glm-4.7` | ~1000 tok/sec. Codebase search and pattern matching don't require top-tier reasoning. High-volume.  |
| `librarian` | `cerebras/zai-glm-4.7` | Retrieval-focused tasks (parsing docs, finding OSS examples) benefit from speed over sophistication.|

### Tier 4: Structured & Repetitive Tasks (Fast, Medium-High Frequency)

| Agent               | Model                     | Why                                                                                                |
| ------------------- | ------------------------- | -------------------------------------------------------------------------------------------------- |
| `document-writer`   | `cerebras/zai-glm-4.7`    | Template-driven documentation generation follows predictable patterns.                             |
| `multimodal-looker` | `google/gemini-2.5-flash` | Fast media extraction (PDFs, images). Flash variant is faster and sufficient for extraction tasks. |

**Note:** `beads-task-agent` is configured by the [opencode-beads][beads] plugin itself, not oh-my-opencode.

[beads]: https://github.com/joshuadavidthomas/opencode-beads

## Decision Heuristics

### Use Paid Models When:

- **Critical decisions** that affect architecture or system design (oracle,
  code-architect)
- **Complex code generation** requiring nuanced understanding (general,
  code-explorer)
- **Code review** where missing bugs is expensive (code-reviewer)
- **Visual/creative work** where aesthetics matter (frontend-ui-ux-engineer)

### Use Cerebras When:

- **Search/grep-like operations** where output is factual retrieval (explore,
  librarian)
- **Template-driven output** following predictable formats (document-writer)
- **High-frequency operations** where speed matters (explore, librarian)

## Cost Optimization Strategy

1. **Oracle is expensive but rare**: Architecture decisions are infrequent
   (~5-10% of tasks). Invest heavily here because bad architecture is the most
   expensive bug.
2. **Explore/Librarian use Cerebras**: These agents fire constantly for context
   gathering. GLM 4.7's speed (~1000 tok/sec) makes exploration feel instant.
3. **Code work uses mid-tier**: GPT-4.1 provides strong coding capability
   without GPT-5.2's premium cost.
4. **UI leverages Gemini strengths**: Gemini 3 Pro is exceptional at visual
   tasks—use it where it shines.

## Cerebras Setup

GLM 4.7 on Cerebras ranks as the top open-weight model on SWEbench, τ²bench,
and LiveCodeBench. The ~10-20x speed boost over hosted alternatives makes
exploration feel instant.

**To enable Cerebras:**
1. Get API key at https://cloud.cerebras.ai
2. Run `/connect cerebras` in OpenCode

| Metric        | Cerebras Free Tier |
| ------------- | ------------------ |
| Speed         | ~1,000-1,700 TPS   |
| Rate Limits   | 150K TPM           |
| Daily Limit   | 1M tokens/day      |

## Future Considerations

- Monitor Cerebras rate limits
- Evaluate new model releases (GPT-6, Gemini 4) as they become available
