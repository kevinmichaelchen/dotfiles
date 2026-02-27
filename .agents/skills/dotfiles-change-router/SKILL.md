---
name: dotfiles-change-router
description: Route dotfiles changes to the correct location in this repository and block common anti-patterns. Use when deciding where a change belongs across nix-darwin, home-manager, chezmoi, mise, scripts, or docs; when a request spans multiple layers; or when validating that a planned edit follows repo conventions.
---

# Dotfiles Change Router

## Overview
Route each requested change to the smallest correct file set before editing anything. Prefer consistency with the repo's "use Nix less" split: stable system/user config in Nix/Home-Manager, fast-iterating personal config in Chezmoi, and dev runtimes in Mise.

## Routing Steps
1. Parse the requested outcome into atomic change intents.
2. Map each intent to exactly one primary owner file.
3. Add secondary files only when required by loading or documentation.
4. Reject anti-pattern placements and reroute.
5. Return a concise "edit plan" listing files and commands to apply/verify.

## Routing Matrix
| Change intent | Primary location | Notes |
| --- | --- | --- |
| macOS defaults, Homebrew brews/casks | `nix-darwin/configuration.nix` | Use for system-level macOS behavior and brew/cask declarations |
| darwin user/host profile wiring | `nix-darwin/flake.nix` | Touch when changing `mkDarwinConfig` users or outputs |
| shared user packages, stable aliases, HM programs | `home-manager/home.nix` | Use for stable shell aliases and Home-Manager-managed programs |
| dev runtimes and CLI toolchain versions | `chezmoi/dot_config/mise/config.toml` | Prefer Mise for node/python/go/rust and many CLIs |
| personal shell behavior and fast iteration aliases | `chezmoi/dot_config/shell/*.sh` | Use plain `.sh` for non-secret config |
| secret-backed env vars | `chezmoi/dot_config/shell/*.sh.tmpl` | Use `onepasswordRead` templates, never hardcode secrets |
| zsh load order/path wiring | `chezmoi/dot_config/zsh/custom.zsh` | Update when adding a new shell module file |
| automation workflow scripts | `scripts/*.sh` | Keep idempotent and non-destructive defaults |
| operator guidance for scripts | `scripts/AGENTS.md` | Update when behavior/contracts change |
| tmux docs/config guidance | `docs/tmux.md` and/or `chezmoi/dot_config/tmux/tmux.conf` | Keep docs and runtime behavior aligned |

## Hard Rules
- Do not put dev runtime/tool version management into `home-manager/home.nix` when it belongs in Mise.
- Do not put secrets into non-template files.
- Do not edit generated user dotfiles directly; edit source in `chezmoi/`.
- Do not add system macOS defaults into Chezmoi shell files.

## Output Contract
Provide:
1. The routed file list with one-line rationale per file.
2. Any anti-patterns detected and the corrected destination.
3. The exact apply/test commands relevant to the touched layers.
