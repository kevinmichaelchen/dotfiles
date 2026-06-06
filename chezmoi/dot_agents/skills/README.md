# Agent Skills

Prefer declaring upstream skills in `~/dotfiles/skills-lock.json` and installing
them with `~/dotfiles/scripts/sync-agent-skills.sh`. This keeps the dotfiles repo
from carrying large vendored skill payloads.

## Layout

Keep any still-vendored skills flat as direct children of this directory.

## Lock-managed upstream skills

These are declared in `~/dotfiles/skills-lock.json` and installed outside the
repo:

- `ast-grep/agent-skill`
  - `ast-grep`
- `firecrawl/cli`
  - `firecrawl`
  - `firecrawl-agent`
  - `firecrawl-crawl`
  - `firecrawl-download`
  - `firecrawl-interact`
  - `firecrawl-map`
  - `firecrawl-parse`
  - `firecrawl-scrape`
  - `firecrawl-search`
- `parallel-web/parallel-agent-skills`
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

## Still-vendored skills

### Custom

These local skills remain vendored until they are moved to an upstream source or
given explicit lock entries:

- `confluence-pages`
- `find-skills`
- `firecrawl-monitor`
- `garden-tender`
- `git-commit-convention`
- `replicate`
