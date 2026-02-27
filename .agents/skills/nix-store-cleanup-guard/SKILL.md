---
name: nix-store-cleanup-guard
description: Perform or update Nix store cleanup workflows with explicit safety checks and retention strategy. Use when reclaiming disk from `/nix/store`, editing `scripts/cleanup.sh`, deciding between aggressive and conservative generation pruning, or preparing cleanup commands for macOS/Linux systems.
---

# Nix Store Cleanup Guard

## Overview
Run cleanup with clear risk signaling, predictable retention policy, and before/after measurements so space recovery does not silently remove required rollback points.

## Workflow
1. Measure current usage and identify urgency.
2. Choose retention mode before deletion.
3. Execute cleanup commands in the correct profile scope.
4. Re-measure and report reclaimed space.
5. Document rollback impact explicitly.

## Retention Modes
| Mode | Behavior | When to choose |
| --- | --- | --- |
| Conservative | Keep recent generations (for example `+3`) before GC | Normal maintenance where rollback matters |
| Aggressive | Delete old generations and run full GC (`-d`) | Disk pressure emergencies or explicit user request |

## Command Patterns
- Measure:
  - `du -sh /nix/store`
- System profile cleanup on macOS:
  - `sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system`
- Home Manager profile cleanup (if present):
  - `nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager`
- User profile cleanup:
  - `nix-env --delete-generations old`
- Garbage collection:
  - `nix-collect-garbage -d`

## Guardrails
- Require explicit confirmation intent before aggressive pruning.
- Prefer conservative retention when no urgency is stated.
- Keep script behavior idempotent and transparent.
- Warn that deleting generations reduces rollback options.

## Completion Checklist
1. Report before/after store size.
2. State chosen retention mode and rationale.
3. State rollback consequences for the chosen mode.
4. Update `scripts/cleanup.sh` and `scripts/AGENTS.md` together when workflow behavior changes.
