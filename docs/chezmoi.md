# Chezmoi Release Status

Last checked: 2026-09-29

## Current Version

| Scope | Version | Source |
| --- | --- | --- |
| This workstation | `v2.71.0` | Homebrew (`/opt/homebrew/bin/chezmoi`) |
| Latest upstream release | `v2.72.1` | [Chezmoi releases][releases] |

An update is available. This repository manages Chezmoi as the Mise bootstrap
package `brew:chezmoi`, so use Mise rather than a standalone installer.

## Notable Changes Since v2.71.0

### v2.72.1

- Adds the `protonPassAttachment` template function for Proton Pass-backed
  attachments.

### v2.72.0

- Adds `shellQuote` and `shellQuoteList` template functions for generating
  shell-safe command arguments.
- Adds `gopassCat` and `debugf` template functions.
- Hardens temporary files, HTTP cache storage, persistent state, archive
  extraction, and handling of untrusted relative paths.

### v2.71.1 and v2.71.0

- Adds `--skip-secrets` and `--verbose` support for upgrade workflows.
- Adds `--error-on-conflict` to make conflicting source and target state fail
  explicitly.
- Adds `--revision` and `--tag` flags to `chezmoi init` for reproducible
  source initialization.

## Relevance To This Repository

- The security hardening is the primary reason to update.
- `shellQuote` and `shellQuoteList` are available for future template work;
  no existing template requires migration.
- The Proton Pass and gopass helpers do not affect the current 1Password-based
  secret workflow.
- No source-format or configuration migration is identified from these release
  notes.

## Upgrade And Verify

```bash
mise bootstrap
chezmoi --version
chezmoi doctor
chezmoi apply --dry-run --source="$HOME/dotfiles/chezmoi"
```

Review the dry-run before applying changes. The repository standard apply
command is `chezmoi apply --source="$HOME/dotfiles/chezmoi"` (or `cma`).

[releases]: https://github.com/twpayne/chezmoi/releases
