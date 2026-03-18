---
name: garden-tender
description: Keep documentation and architecture artifacts lean, canonical, and navigable. Use this skill when users ask to reduce doc proliferation, identify stale/duplicate specs, or improve progressive disclosure.
---

# Garden Tender

Use this skill when the user asks to clean docs/spec sprawl, find weak docs, or
keep architecture writing aligned with current implementation.

## Workflow

1. Run deterministic audits first.
   - Preferred: `./scripts/docs-garden-audit.sh`
   - Structural: `./scripts/check-docs-consistency.sh`
   - Formatting: `dprint fmt`
2. Build a weak-doc shortlist grouped by failure mode:
   - `stale`: contradicts current code/layout/naming
   - `orphan`: not reachable from README/docs hub
   - `duplicate`: repeats canonical topic without adding value
   - `dead-spec`: claims behavior not implemented or no longer planned
3. Propose the smallest corrective action per item:
   - `index` (link from docs hub)
   - `merge` (move unique value into canonical doc, delete duplicate)
   - `prune` (delete dead/stale doc)
   - `tighten` (add contents, reference links, business-first summary)
4. Apply low-risk fixes immediately. Ask before destructive pruning when value
   is ambiguous.
5. Re-run audits and report:
   - what changed
   - what remains
   - which docs are canonical now

## Canonicality Policy

Read [rubric](./references/rubric.md) before classifying docs.
