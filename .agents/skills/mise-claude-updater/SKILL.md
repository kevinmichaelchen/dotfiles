---
name: mise-claude-updater
description: Upgrade and prune all Mise-managed tools, then update Claude Code. Use when asked to bring developer CLIs to latest versions and verify the result.
---

# Mise + Claude Updater

## Overview
Run the repository standard workflow for developer tool updates:
- update all outdated Mise tools
- prune unused Mise versions
- update Claude Code
- verify final state

Primary entrypoint: `scripts/update-tools.sh`.

## Workflow
1. Run `./scripts/update-tools.sh` from repo root.
2. If it reports `mise not found` or `claude not found`, report that explicitly.
3. Confirm success with:
   - `mise outdated` (should report all tools up to date)
   - `claude --version` (if Claude installed)
4. Summarize any fallback used (for example `MISE_GITHUB_ATTESTATIONS=false` for `github:cli/cli`).

## Guardrails
- Do not edit `chezmoi/dot_config/mise/config.toml` for update-only requests.
- Do not run full system updates unless requested (`scripts/update.sh` does Nix/Home-Manager too).
- Keep changes idempotent and safe to rerun.

## Completion Checklist
1. Report whether `mise upgrade` succeeded.
2. Report whether `mise prune --yes` succeeded.
3. Report Claude update result and final version.
4. Provide the exact command for next run: `./scripts/update-tools.sh`.
