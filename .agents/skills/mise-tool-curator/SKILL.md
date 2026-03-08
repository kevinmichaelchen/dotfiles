---
name: mise-tool-curator
description: Curate and maintain `chezmoi/dot_config/mise/config.toml` for developer runtimes and CLI tools. Use when adding, removing, pinning, or migrating tools in Mise; selecting the correct source type (`npm`, `cargo`, `go`, `github`, `aqua`); or resolving duplication between Mise and Nix/Homebrew.
---

# Mise Tool Curator

## Overview
Manage tool declarations in `chezmoi/dot_config/mise/config.toml` so runtime ownership stays consistent and installs remain reproducible.

## Workflow
1. Classify requested tool change: add, remove, pin, or migrate source.
2. Choose the most appropriate Mise source type.
3. Insert/edit the tool in the correct section, preserving organization.
4. Check for duplicate ownership in `home-manager/home.nix` and `nix-darwin/configuration.nix`.
5. Provide post-edit apply commands, maintenance commands, and verification steps.

## Source Selection Heuristics
| Tool type | Prefer |
| --- | --- |
| Language runtime (node/python/go/rust) | native runtime key (for example `node = "24"`) |
| Node CLI | `npm:<package>` |
| Rust CLI crate | `cargo:<crate>` |
| Go CLI from module path | `go:<module/cmd/...>` |
| GitHub release binary | `github:owner/repo` |
| Verified binary in aqua registry | `aqua:owner/repo` |

## Guardrails
- Avoid placing dev-tool version management in Home-Manager unless explicitly requested.
- Keep comments that explain why a tool is intentionally managed outside Mise.
- Prefer minimal edits in existing section layout.
- Do not leak secret tokens into this file.

## Completion Checklist
1. Summarize changed keys in `chezmoi/dot_config/mise/config.toml`.
2. Call out any ownership conflicts discovered and how they were resolved.
3. Provide commands:
   - `cma`
   - `mise install`
   - `mise upgrade`
   - `mise prune --yes`
   - optional verification: `mise ls` or `mise doctor`
