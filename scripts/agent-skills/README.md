# Agent Skill Scripts

These scripts keep upstream agent skills out of the dotfiles repo while still
installing reproducible, scanned copies into `~/.agents/skills`.

## Commands

- `sync.sh --prune`: install pinned skills from `skills-lock.json`, validate
  `computedHash`, scan each downloaded skill, and prune removed lock entries.
  Targets outside `~/.agents/skills` require an explicit `--target DIR`.
- `update-lock.sh`: resolve each `trackRef` to the latest upstream commit, scan
  each downloaded skill, compute its directory hash, and print a proposed
  `skills-lock.json` diff. Rerun with `--apply` after reviewing the diff.
- `scan.sh --all`: scan installed lock-managed skills and still-vendored
  Chezmoi skills.

`scan.sh`, `sync.sh`, and `update-lock.sh` require NVIDIA SkillSpector for
per-skill filesystem scanning.
