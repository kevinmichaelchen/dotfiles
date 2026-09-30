# Agent Skills

Prefer declaring upstream skills in `~/dotfiles/skills-lock.json` and installing
them with `~/dotfiles/scripts/agent-skills/sync.sh`. This keeps the dotfiles
repo from carrying large vendored skill payloads.

## Layout

Keep any still-vendored skills flat as direct children of this directory.

## Lock-managed upstream skills

These are declared in `~/dotfiles/skills-lock.json` and installed outside the
repo. Each lock entry pins the upstream commit and a computed directory hash, so
updates are explicit and reviewable instead of blindly pulling the latest repo
state.

- [`ast-grep/agent-skill`](https://github.com/ast-grep/agent-skill)
  - `ast-grep`
- [`firecrawl/cli`](https://github.com/firecrawl/cli)
  - `firecrawl`
  - `firecrawl-agent`
  - `firecrawl-crawl`
  - `firecrawl-download`
  - `firecrawl-interact`
  - `firecrawl-map`
  - `firecrawl-parse`
  - `firecrawl-scrape`
  - `firecrawl-search`
- [`parallel-web/parallel-agent-skills`](https://github.com/parallel-web/parallel-agent-skills)
  - `parallel-cli-setup`
  - `parallel-data-enrichment`
  - `parallel-deep-research`
  - `parallel-findall`
  - `parallel-monitor`
  - `parallel-web-extract`
  - `parallel-web-search`
  - `result`
  - `status`

## Security pipeline

Run `~/dotfiles/scripts/agent-skills/scan.sh --all` to scan all installed
lock-managed skills plus all still-vendored skills. `sync.sh` and
`update-lock.sh` also run SkillSpector on downloaded upstream skill directories
by default.

## Claude Code projection

`~/.agents/skills` is the canonical global skill directory shared by Codex,
Claude Code, Crush, and OpenCode. Mise links `~/.claude/skills` to it.
Mise links the still-vendored skill files individually; the sync script owns
lock-managed skill directories and leaves vendored files alone.

## Still-vendored skills

### Custom

These local skills remain vendored until they are moved to an upstream source or
given explicit lock entries:

- `find-skills`
- `firecrawl-monitor`
