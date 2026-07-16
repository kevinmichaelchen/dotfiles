---
name: dotfiles-change-router
description: Route dotfiles changes to the correct location in this repository and block common anti-patterns. Use when deciding where a change belongs across Chezmoi, Mise, scripts, or docs; when a request spans multiple layers; or when validating that a planned edit follows repo conventions.
---

# Dotfiles Change Router

## Overview
Route each requested change to the smallest correct file set before editing anything. Mise owns machine convergence and tool installation; Chezmoi owns personal configuration and shell behavior.

## Routing Steps
1. Parse the requested outcome into atomic change intents.
2. Map each intent to exactly one primary owner file.
3. Add secondary files only when required by loading or documentation.
4. Reject anti-pattern placements and reroute.
5. Return a concise "edit plan" listing files and commands to apply/verify.

## Routing Matrix
| Change intent | Primary location | Notes |
| --- | --- | --- |
| macOS defaults, Homebrew brews/casks | `chezmoi/dot_config/mise/config.toml` | Use Mise bootstrap declarations for machine state |
| dev runtimes and CLI toolchain versions | `chezmoi/dot_config/mise/config.toml` | Prefer Mise for node/python/go/rust and CLIs |
| shared aliases and environment | `chezmoi/dot_config/shell/*.sh` | Keep shell-agnostic behavior in focused modules |
| global agent skills for `~/.agents/skills` | `chezmoi/dot_agents/skills/` | Use for skills that should be available across repos/tools on this machine |
| repo-local dotfiles skills | top-level `.agents/skills/` | Use only for skills specific to maintaining this dotfiles repo |
| personal shell behavior and fast iteration aliases | `chezmoi/dot_config/shell/*.sh` | Use plain `.sh` for non-secret config |
| tool authentication | provider CLI or connected app | Keep API keys and bearer tokens out of Chezmoi; use browser/OAuth login or provider-owned credential storage |
| zsh load order/path wiring | `chezmoi/dot_config/zsh/custom.zsh` | Update when adding a new shell module file |
| automation workflow scripts | `scripts/*.sh` | Keep idempotent and non-destructive defaults |
| operator guidance for scripts | `scripts/AGENTS.md` | Update when behavior/contracts change |
| tmux docs/config guidance | `docs/tmux.md` and/or `chezmoi/dot_config/tmux/tmux.conf` | Keep docs and runtime behavior aligned |

## Hard Rules
- Do not introduce a second package or machine-configuration owner alongside Mise.
- Do not put dotfiles-specific skills into `chezmoi/dot_agents/skills`; those belong in top-level `.agents/skills`.
- Do not put secrets or secret-fetching templates in Chezmoi.
- Do not edit generated user dotfiles directly; edit source in `chezmoi/`.
- Do not add system macOS defaults into Chezmoi shell files.

## Output Contract
Provide:
1. The routed file list with one-line rationale per file.
2. Any anti-patterns detected and the corrected destination.
3. The exact apply/test commands relevant to the touched layers.
