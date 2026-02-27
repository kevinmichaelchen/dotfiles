---
name: home-manager-maintainer
description: Maintain `home-manager/home.nix` safely and consistently for packages, Home-Manager program settings, session variables, and stable aliases. Use when adding/removing Home-Manager-managed packages or program options, adjusting stable shell aliases, or refactoring `home.nix` while preserving repository conventions.
---

# Home Manager Maintainer

## Overview
Edit `home-manager/home.nix` with minimal, convention-preserving changes. Keep ownership boundaries clear with nix-darwin, Chezmoi, and Mise.

## Workflow
1. Read current `home-manager/home.nix` sections before editing.
2. Identify the smallest section to modify: `home.packages`, `programs.*`, `home.sessionVariables`, or `home.shellAliases`.
3. Apply the change with existing ordering and comment style.
4. Check for ownership conflicts with Mise and nix-darwin.
5. Provide apply commands for macOS and Linux paths.

## Scope Boundaries
| In scope for this skill | Out of scope for this skill |
| --- | --- |
| `home.packages` entries | macOS Homebrew settings in `nix-darwin/configuration.nix` |
| HM program options (zsh/fzf/starship/home-manager) | dev runtime version management in `chezmoi/dot_config/mise/config.toml` |
| stable aliases in `home.shellAliases` | fast-changing personal aliases in `chezmoi/dot_config/shell/*.sh` |
| environment variables suitable for HM | secret values that belong in Chezmoi templates |

## Guardrails
- Preserve `home.stateVersion` unless explicitly requested with migration context.
- Keep bootstrap-critical tooling already documented in place unless the request explicitly migrates ownership.
- Prefer additive edits over broad reformatting.
- Preserve compatibility with both darwin-embedded HM and standalone Linux HM usage.

## Completion Checklist
1. State exactly what changed in `home-manager/home.nix`.
2. Flag any attempted cross-layer misplacement and the corrected layer.
3. Provide relevant apply command:
   - macOS: `darwin-rebuild switch --flake ~/dotfiles/nix-darwin#default`
   - Linux: `nix run home-manager -- switch --flake ~/dotfiles/home-manager`
