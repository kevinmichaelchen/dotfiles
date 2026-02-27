---
name: git-commit-convention
description: Create Git commits with a semi-detailed Conventional Commit message using heredoc input. Use when asked to commit current changes, draft commit text, or enforce repository commit style.
---

# Git Commit Convention

## Overview
Create commits with:
- Conventional Commit subject line.
- Semi-detailed body (concise but informative).
- Heredoc commit input (`git commit -F - <<'EOF'`), not `-m`.

## Workflow
1. Inspect pending changes with `git status --short`.
2. Review staged content with `git diff --staged --stat` and `git diff --staged`.
3. If nothing is staged, stage the intended files (`git add <paths>` or `git add -A` when explicitly appropriate).
4. Choose commit type and optional scope from the staged diff.
5. Commit with heredoc using the format below.
6. Verify with `git show --stat --oneline -1`.

## Commit Format
First line:
- `<type>(<scope>): <summary>`
- Scope is optional: `<type>: <summary>`

Allowed common types:
- `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `build`, `perf`, `style`, `revert`

Subject rules:
- Imperative mood (`add`, `fix`, `update`, not `added`/`fixes`).
- No trailing period.
- Keep concise (target <= 72 chars).

Body rules (semi-detailed):
- 2-4 bullet lines.
- Explain what changed and why it matters.
- Mention key files/components when useful.
- Avoid noisy implementation trivia.

Footer:
- Add only when needed (e.g., `BREAKING CHANGE: ...`, `Refs: #123`).

## Heredoc Template
```bash
git commit -F - <<'EOF'
feat(scope): short imperative summary

- describe the primary change and intent
- capture a second meaningful implementation detail
- note impact, migration, or behavior change when relevant
EOF
```

## Guardrails
- Do not use `git commit -m` with this convention.
- Do not include secrets, tokens, or generated noise in commit bodies.
- Keep messages specific to staged changes only.
