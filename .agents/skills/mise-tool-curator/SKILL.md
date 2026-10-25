---
name: mise-tool-curator
description: Curate and maintain `mise/config.toml` for developer runtimes and CLI tools. Use when adding, removing, pinning, or migrating tools in Mise; selecting the correct source type (`npm`, `cargo`, `go`, `github`, `aqua`); or resolving duplicate package ownership.
---

# Mise Tool Curator

## Overview
Manage tool declarations in `mise/config.toml` so runtime ownership stays consistent and installs remain reproducible.

## Workflow
1. Classify requested tool change: add, remove, pin, or migrate source.
2. Choose the most appropriate Mise source type.
3. Insert/edit the tool in the correct section, preserving organization.
4. Check for duplicate ownership between Mise tools and bootstrap packages.
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
- Keep versioned developer tools in Mise rather than ad hoc installers.
- Keep comments that explain why a tool is intentionally managed outside Mise.
- Keep agent harness binaries (Codex, Claude Code, OpenCode, and similar tools) outside Mise; use native installers and updaters. Mise may still manage their shared app config.
- Prefer minimal edits in existing section layout.
- Do not leak secret tokens into this file.

## Apply and verify

Use the narrowest operation: `mise install TOOL` for a declared tool,
`MISE_LOCKED=false mise upgrade --bump --no-prune TOOL` for an authorized pin update, and
`mise dotfiles apply TARGET` for a managed config. Preview conflicting targets
before applying. Do not run full `mise bootstrap` for a tool-only change.

The global config and lockfile must resolve to `mise/config.toml` and
`mise/mise.lock` in this repository. Check for stale copies with `ls -l` and
`mise config ls`; manage the links through declared dotfile entries.

Refresh `mise lock --global --platform macos-arm64`. Review the generated
`mise/.mise/locks/` dependency sidecars with the config and lockfile; commit
them together when a commit is requested. Keep release-age and provenance
settings intact. Use `mise install --locked` for reproducible installs.

Verify tool selection both inside the repository and outside it using
`mise which TOOL` and `mise -C /private/tmp which TOOL`, then smoke-test versions.

Never execute deletion commands or scripts that delete files internally.
For tool retirement, edit declarations, preview `mise prune --dry-run`, and
provide exact uninstall/prune commands for the operator to run manually.
