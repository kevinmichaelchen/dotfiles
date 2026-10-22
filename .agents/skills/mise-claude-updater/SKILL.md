---
name: mise-claude-updater
description: Update Mise-managed tools and Claude Code, verify versions, and preview unused installations without deleting them.
---

# Mise + Claude Updater

Run `./scripts/update-tools.sh` from the repo root. It selects the repository's
authoritative global config, upgrades runtimes before dependent packages,
refreshes the lockfile, previews pruning, and invokes `claude update`.

- Authorized updates may change exact pins through `mise upgrade --bump`.
  Preserve the seven-day release-age policy and its declared exceptions.
- Routine installs are locked. `scripts/update-tools.sh` explicitly sets
  `MISE_LOCKED=false` for its maintenance run; targeted upgrades must do the
  same. Leave the shared `locked = true` default intact.
- Never execute deletion commands, including uninstall or actual pruning.
  `mise prune --dry-run` is allowed; give the operator exact cleanup commands.
  Do not run scripts that delete files internally.
- Do not run full workstation convergence for a tool-update request.
- Keep provenance verification enabled. Investigate failures rather than
  automatically disabling attestations.
- If a lockfile cannot be parsed, stop before pruning. Use supported lockfile
  migration, then confirm resolution works; do not mistake warnings followed
  by an empty outdated table for success.

Verify `mise outdated --bump`, the changed tools' versions, and
`claude --version`. Report missing CLIs and unresolved release lookups.
Review config, lockfile, and `.mise/locks/` sidecars together. Report the
remaining manual cleanup, and provide `./scripts/update-tools.sh` for next time.
