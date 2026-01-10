# Oh-My-OpenCode Model Assignment Rationale

## Overview

This configuration optimizes cost-effectiveness while maintaining high-quality
output by allocating models based on task complexity, frequency, and required
capabilities.

## Available Model Tiers

### Paid Models (Subscription-based)

- **OpenAI**: GPT-5.2, GPT-5.1, GPT-4.1
- **Google**: Gemini 3 Pro, Gemini 2.5 Flash

### Free Models (OpenCode-hosted)

- **GLM**: glm-4.7-free (speed undocumented, likely <100 TPS)

### Fast Models (Direct API)

- **Cerebras**: GLM 4.7 (~1,000-1,700 tokens/sec)

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

### Tier 3: High-Frequency Search & Retrieval (Free, High Frequency)

| Agent       | Model                   | Why                                                                                              |
| ----------- | ----------------------- | ------------------------------------------------------------------------------------------------ |
| `explore`   | `opencode/glm-4.7-free` | Codebase search and pattern matching don't require top-tier reasoning. High-frequency operation. |
| `librarian` | `opencode/glm-4.7-free` | Retrieval-focused tasks (parsing docs, finding OSS examples) are lower complexity.               |

### Tier 4: Structured & Repetitive Tasks (Free, Medium-High Frequency)

| Agent               | Model                     | Why                                                                                                |
| ------------------- | ------------------------- | -------------------------------------------------------------------------------------------------- |
| `document-writer`   | `opencode/glm-4.7-free`   | Template-driven documentation generation follows predictable patterns.                             |
| `beads-task-agent`  | `opencode/glm-4.7-free`   | Completes ready tasks—pattern matching, not deep reasoning.                                        |
| `multimodal-looker` | `google/gemini-2.5-flash` | Fast media extraction (PDFs, images). Flash variant is faster and sufficient for extraction tasks. |

## Decision Heuristics

### Use Paid Models When:

- **Critical decisions** that affect architecture or system design (oracle,
  code-architect)
- **Complex code generation** requiring nuanced understanding (general,
  code-explorer)
- **Code review** where missing bugs is expensive (code-reviewer)
- **Visual/creative work** where aesthetics matter (frontend-ui-ux-engineer)

### Use Free Models When:

- **Search/grep-like operations** where output is factual retrieval (explore,
  librarian)
- **Template-driven output** following predictable formats (document-writer)
- **Pattern matching** on ready tasks (beads-task-agent)
- **High-frequency operations** where cost would accumulate (explore, librarian)

## Cost Optimization Strategy

1. **Oracle is expensive but rare**: Architecture decisions are infrequent
   (~5-10% of tasks). Invest heavily here because bad architecture is the most
   expensive bug.
2. **Explore/Librarian are free but frequent**: These agents fire constantly
   for context gathering. Using free models here saves the most.
3. **Code work uses mid-tier**: GPT-4.1 provides strong coding capability
   without GPT-5.2's premium cost.
4. **UI leverages Gemini strengths**: Gemini 3 Pro is exceptional at visual
   tasks—use it where it shines.

## Cerebras Upgrade Path (For Speed)

If `opencode/glm-4.7-free` feels slow, consider switching to `cerebras/glm-4.7`:

| Metric            | OpenCode Free        | Cerebras Direct          |
| ----------------- | -------------------- | ------------------------ |
| Speed             | Undocumented (<100?) | ~1,000-1,700 TPS         |
| Rate Limits       | 5-hour quota cycles  | 150K TPM (free tier)     |
| Daily Limit       | Unknown              | 1M tokens/day (free)     |
| Cost              | Free                 | Free tier, then $10 min  |

**To enable Cerebras:**
1. Get API key at https://cloud.cerebras.ai
2. Run `/connect cerebras` in OpenCode
3. Update `oh-my-opencode.json` agents to use `cerebras/glm-4.7`

GLM 4.7 on Cerebras ranks as the top open-weight model on SWEbench, τ²bench,
and LiveCodeBench. The ~10-20x speed boost makes exploration feel instant.

## Future Considerations

- Try Cerebras free tier to benchmark speed improvement
- Monitor Cerebras rate limits if upgraded
- Evaluate new model releases (GPT-6, Gemini 4) as they become available
- If Anthropic support is restored, consider Claude for `oracle` and `code-explorer`
