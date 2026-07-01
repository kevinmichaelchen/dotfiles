# Agent Skill Scripts

These scripts keep upstream agent skills out of the dotfiles repo while still
installing reproducible, scanned copies into `~/.agents/skills`.

`~/.agents/skills` is the canonical runtime directory for shared global skills.
Claude Code gets a curated projection from Chezmoi-managed symlinks under
`~/.claude/skills`; that projection should mirror portable global skills unless
a skill is explicitly Codex-specific, private, broken, or otherwise unsuitable
for Claude Code.

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

## Adding public upstream skills

Prefer adding public skills to `skills-lock.json` instead of vendoring their
payloads in this repo. `update-lock.sh` resolves the upstream ref, scans the
downloaded skill, and records the computed directory hash. `sync.sh` then
downloads to a temporary work directory, verifies the hash, scans again, and
installs the reviewed copy into `~/.agents/skills`.

After the skill is reproducible from the lock, add a Chezmoi symlink source in
`chezmoi/dot_claude/skills/` unless it is a documented exception.
