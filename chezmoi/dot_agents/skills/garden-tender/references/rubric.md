# Docs Garden Rubric

## Contents

- [Classification Signals](#classification-signals)
- [Action Matrix](#action-matrix)
- [Priority Order](#priority-order)

## Classification Signals

| Class | Signal | Typical example |
| --- | --- | --- |
| stale | Path/name/system shape no longer true | old directory name in links |
| orphan | Not linked from README/docs index | tooling doc nobody can discover |
| duplicate | Same topic covered in multiple docs | 2 architecture overviews with drift |
| dead-spec | Promises behavior not in code/tests | feature doc for unplanned behavior |
| unclear | Missing structure/progressive disclosure | no contents or canonical references |

## Action Matrix

| Class | Preferred action | Notes |
| --- | --- | --- |
| stale | tighten | update paths/terminology; avoid compatibility language |
| orphan | index | add hub links before creating new docs |
| duplicate | merge | retain one source of truth |
| dead-spec | prune | remove quickly unless explicitly re-scoped |
| unclear | tighten | add `## Contents`, business value first, refs |

## Priority Order

1. Contradictions and stale claims.
2. Dead specs that mislead implementation.
3. Orphans that block discoverability.
4. Duplication that creates drift.
5. Style polish.
