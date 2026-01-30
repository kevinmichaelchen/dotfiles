# Oh-My-OpenCode Model Assignment Rationale

## Overview

This configuration prioritizes **code review quality** while optimizing for
speed where it matters. Models are assigned based on task criticality, with
code-focused tasks using OpenAI's Codex variants and **Kimi K2.5** for
high-quality, high-throughput general tasks.

## Available Model Tiers

### OpenAI Codex (Code-Optimized)

- **gpt-5.2-codex**: Top-tier reasoning + code optimization
- **gpt-5.1-codex-max**: Strong code capability, maximum at 5.1
- **gpt-5.1-codex-mini**: Lighter, faster, still code-optimized

### OpenAI General

- **gpt-5.2**: Best pure reasoning (non-code-specific)

### Kimi K2.5 (Primary Workhorse)

| Model         | SWE-bench Verified | SWE-bench Pro | Context | Use Case                     |
| ------------- | ------------------ | ------------- | ------- | ---------------------------- |
| **Kimi K2.5** | 76.8%              | 50.7%         | 256K    | General purpose, exploration |

**Kimi K2.5 Advantages:**

- **Best-in-class SWE-bench**: 76.8% Verified (competitive with GPT-5.2 at ~80%)
- **Massive context**: 256K tokens (~200K words)
- **Strong agentic capabilities**: Parallel processing, agent swarms
- **Multilingual excellence**: 73.0% SWE-multilingual (leads most models)
- **1T MoE architecture**: 32B activated params for efficiency
- **Multimodal**: Supports text, images, videos, PDFs

### Legacy Fast Models (Reference)

| Model            | SWE-bench                             | Speed      | Cost (in/out) | Use Case                                |
| ---------------- | ------------------------------------- | ---------- | ------------- | --------------------------------------- |
| **GLM 4.7**      | 73.8%                                 | ~1,000 t/s | $2.25/$2.75   | Quality exploration (≈ Haiku 4.5)       |
| **MiniMax M2.1** | 74% (Verified) / 72.5% (Multilingual) | ~1,500 t/s | $0.30/$1.20   | Multilingual coding & agentic workflows |

**Note:** Kimi K2.5 outperforms both GLM 4.7 and MiniMax M2.1 on SWE-bench while
offering 256K context. Preferred for most general tasks.

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

### Tier 2: Quality-Critical Tasks (GPT-5.2 Codex)

| Agent             | Model                        | Why                                                   |
| ----------------- | ---------------------------- | ----------------------------------------------------- |
| `code-explorer`   | `openai/gpt-5.2-codex-xhigh` | Maximum reasoning for deep code path analysis.        |
| `document-writer` | `openai/gpt-5.2-codex-high`  | High-quality prose + code examples for documentation. |

### Tier 3: General Purpose & Exploration (Kimi K2.5)

| Agent       | Model                     | Why                                                                 |
| ----------- | ------------------------- | ------------------------------------------------------------------- |
| `general`   | `opencode/kimi-k2.5-free` | Best free model (76.8% SWE-bench). Strong reasoning + 256K context. |
| `explore`   | `opencode/kimi-k2.5-free` | High-quality exploration with massive context for large codebases.  |
| `librarian` | `opencode/kimi-k2.5-free` | Excellent multilingual understanding (73% SWE-multilingual).        |

### Tier 4: Specialized Visual Tasks (Google)

| Agent                     | Model                      | Why                                                         |
| ------------------------- | -------------------------- | ----------------------------------------------------------- |
| `frontend-ui-ux-engineer` | `google/gemini-3-pro-high` | Gemini excels at visual reasoning and creative UI/UX tasks. |
| `multimodal-looker`       | `google/gemini-2.5-flash`  | Vision capability required. Flash is fast and sufficient.   |

## Design Principles

### Code Review is Sacrosanct

The `code-reviewer` agent uses `gpt-5.2-codex`—the absolute best available for
code analysis. Missing a bug or security issue is far more expensive than the
model cost.

### Kimi K2.5 as Primary Workhorse

Kimi K2.5 is the default model and powers most agents because:

- **76.8% SWE-bench Verified** — Outperforms GLM 4.7 (73.8%) and MiniMax M2.1
  (74%)
- **256K context** — Handles large codebases without truncation
- **Strong agentic capabilities** — Parallel processing, systematic
  problem-solving
- **Multilingual excellence** — 73% SWE-multilingual for polyglot codebases

### Codex for Mission-Critical Code Tasks

- Use `-codex` variants for code review and architecture (highest stakes)
- Use `gpt-5.2` for pure reasoning tasks requiring maximum capability

### Gemini for Visual/Creative Work

Google's Gemini models excel at visual and creative tasks. Use them where those
strengths matter (UI/UX, multimodal vision tasks).

## Model Reference

### Kimi K2.5 Specs

| Metric           | Value                     |
| ---------------- | ------------------------- |
| Architecture     | 1T MoE (32B activated)    |
| Context Window   | 256K tokens               |
| SWE-bench        | 76.8% Verified, 50.7% Pro |
| SWE-multilingual | 73.0%                     |
| Modalities       | Text, images, video, PDF  |

### Fallback Options

If Kimi K2.5 is unavailable, these models provide alternatives:

| Model        | SWE-bench | Context | Notes                 |
| ------------ | --------- | ------- | --------------------- |
| MiniMax M2.1 | 74%       | ~128K   | Fast, multilingual    |
| GLM 4.7      | 73.8%     | ~128K   | Cerebras-hosted, fast |
