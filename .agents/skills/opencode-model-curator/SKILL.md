---
name: opencode-model-curator
description: Research and maintain this dotfiles repository's OpenCode v2 model options. Use when updating OpenCode model choices or comparing recently discussed open-weight models on Fireworks and OpenRouter using current prices, measured speeds, and shared benchmarks.
---

# OpenCode Model Curator

Read `dotfiles/.config/opencode/README.md` for the current shortlist, dated
comparison, billing routes, and subscription context. Shared settings belong in
`dotfiles/.config/opencode/dotfiles.json`; this skill stays project-scoped under
`.agents/skills/`. The official native installer owns the CLI installation;
Mise only deploys shared configuration.

## Research before changing the shortlist

- Check local config, installed OpenCode version, and its model catalog first.
  Inspect credential provider names/types only; never print keys or OAuth tokens.
- Use the available web-research workflow (normally Parallel search/extraction)
  to find current releases, then verify exact versions, released weights, model
  IDs, and serverless availability against labs and provider catalogs. An API
  listing alone does not establish open weights. A Fireworks on-demand listing
  does not establish pay-per-token serverless access.
- Check recent X discussion to discover candidates and explain current hype.
  Use Birdclaw's cache first, then bounded read-only bird searches if available.
  Preserve raw captures under gitignored `.context/x/`; record dates, queries,
  result limits, and retrieval gaps. Use separate queries/windows when one
  promotion dominates results. Avoid treating posts, likes, rumors, or vendor
  benchmark graphics as independent performance measurements.
- Honor explicit model/provider preferences. Consider alternatives that add
  useful options alongside the user's existing subscriptions; do not silently
  replace their default or assume another subscription purchase is wanted.

## Compare objective numbers

Produce a dated table with links to primary sources. Include what is available:

- USD per 1M uncached input, cached input, and output tokens, with the named
  serving provider and service tier. On OpenRouter, inspect
  `https://openrouter.ai/api/v1/models/{author}/{slug}/endpoints` as well as
  `https://openrouter.ai/api/v1/models`. Model-summary prices are not a reliable
  substitute for a particular endpoint's prices. Keep quantization, batch/flex
  discounts, region, and routing constraints visible when they affect comparison.
- Measured output tokens/second, time to first token, and time to first answer
  token where available. State measurement source, endpoint, and date. AA's
  first-party/provider-median speeds are not measurements of the user's route.
  Null telemetry is unavailable, not zero. Do not substitute advertised peak
  throughput or accelerator benchmarks for hosted API speed.
- Independent shared benchmarks with the same evaluator, benchmark version,
  harness, and disclosed reasoning effort. AA comparison pages are useful for
  a common index and individual coding/agent/long-context scores. Distinguish
  vendor reports from evaluator-run results. Do not mix Terminal-Bench versions
  or treat an intelligence index as a percentage. Mark unavailable or under-review
  data, snapshot differences, and unknown methodology rather than filling gaps.
- Context/output limits and input modalities when relevant. Reasoning/output
  token use or measured benchmark cost per task can explain why token price
  alone does not predict total cost. Label any calculated example's token mix.

Use OpenRouter Compare and model provider pages for endpoint comparisons; use
independent evaluators for performance comparisons. Verify a Fireworks comparison
feature exists before linking it. Keep recommendations separate from measured
facts. Do not invent subjective scores for autonomy, code quality, or taste;
the user uses X for qualitative context. Paid inference is a separate benchmark
activity: do not run it merely to update settings or documentation.

## Apply native v2 settings

- Use `providers.<provider>.models.<catalog-id>` with `disabled: false` for
  existing catalog entries. Preserve upstream limits, capabilities, prices,
  and variants rather than maintaining copies or creating aliases needlessly.
  If an entry is absent, verify metadata before adding a custom definition;
  an empty new entry can acquire incorrect fallback capabilities/limits.
- Preserve the app-owned primary model, OAuth connections, title model, other
  selectable models, and OpenRouter `body.provider.data_collection: "deny"`.
  Do not introduce a provider/model allowlist for a shortlist of optional models.
  Explicit enables can override local disables; disclose that behavior.
- Use full provider-specific IDs. OpenRouter and direct Fireworks calls use
  separate credit balances; routing through Fireworks on OpenRouter still bills
  OpenRouter. Login through native `/connect` or `opencode auth login`; never
  store credentials in this repository.
- Read current v2 docs and validate with the installed v2 CLI. The public
  `https://opencode.ai/config.json` returned a v1 schema on 2026-10-16 despite
  v2 docs linking it. Do not migrate working v2 `providers`, `settings`,
  `mcp.servers`, or `agents.title.model` back to v1 shapes to satisfy that schema.
- Update the existing OpenCode README's shortlist, dated numbers, source links,
  and caveats together. Keep large raw captures and rendered PR images out of Git.
  Link this skill from the repository's maintenance guidance for future agents.

## Verify

Run `python3 scripts/check-opencode-v2.py` for isolated native config loading,
catalog selection, inherited metadata, and preservation of local choices. The
fixture uses the installed CLI's fixed catalog snapshot and placeholder API
keys, with live model refresh disabled and no inference requests. Check live
provider availability separately during research. Run
`python3 scripts/check-native-config.py` when shared loading behavior changes.
Use `opencode models` or `/models` in the user's project to check actual provider
availability when needed; credentials and policies are location-scoped.

Report the exact checks run, catalog versus authenticated/inference verification,
and remaining gaps. Use the repository's normal PR workflow when requested.
