# Agent Skill Scripts

These scripts keep upstream agent skills out of the dotfiles repo while still
installing reproducible, scanned copies into `~/.agents/skills`.

`~/.agents/skills` is the canonical runtime directory for shared global skills.
The app-config script links `~/.claude/skills` to this canonical directory so
Claude Code sees the same installed skills.

## Commands

- `sync.sh --prune`: install pinned skills from `skills-lock.json`, validate
  `computedHash`, scan each downloaded skill, and prune removed lock entries.
  Targets outside `~/.agents/skills` require an explicit `--target DIR`.
- `update-lock.sh`: resolve each `trackRef` to the latest upstream commit, scan
  each downloaded skill, compute its directory hash, and print a proposed
  `skills-lock.json` diff. Rerun with `--apply` after reviewing the diff.
- `scan.sh --all`: scan installed lock-managed skills and still-vendored
  repository skills.

`scan.sh`, `sync.sh`, and `update-lock.sh` require NVIDIA SkillSpector for
per-skill filesystem scanning.

## Adding public upstream skills

Prefer adding public skills to `skills-lock.json` instead of vendoring their
payloads in this repo. `update-lock.sh` resolves the upstream ref, scans the
downloaded skill, and records the computed directory hash. `sync.sh` then
downloads to a temporary work directory, verifies the hash, scans again, and
installs the reviewed copy into `~/.agents/skills`.

Claude Code uses the app-config-managed `~/.claude/skills` link to the canonical
`~/.agents/skills` directory. New lock-managed skills appear there after sync.
