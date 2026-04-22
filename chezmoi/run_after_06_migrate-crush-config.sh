#!/usr/bin/env bash
# Move the legacy Crush config out of the runtime data path when it still
# matches the old static chezmoi-managed file.

set -euo pipefail

LEGACY_PATH="${HOME}/.local/share/crush/crush.json"
BACKUP_PATH="${LEGACY_PATH}.chezmoi-legacy-config.bak"

if [[ ! -f "${LEGACY_PATH}" ]]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Warning: jq not found, skipping Crush legacy config migration"
  exit 0
fi

if jq -e '
  .["$schema"] == "https://charm.land/crush.json" and
  .providers["openrouter-fireworks"].type == "openai-compat" and
  .providers.openrouter.type == "openai-compat" and
  .models.large.model == "moonshotai/kimi-k2.6" and
  .models.small.model == "google/gemini-2.5-flash-lite" and
  .options.context_paths == ["CLAUDE.md", "AGENTS.md", ".cursorrules"]
' "${LEGACY_PATH}" >/dev/null 2>&1; then
  if [[ -e "${BACKUP_PATH}" ]]; then
    BACKUP_PATH="${BACKUP_PATH}.$(date +%Y%m%d%H%M%S)"
  fi

  mv "${LEGACY_PATH}" "${BACKUP_PATH}"
  echo "Moved legacy Crush config to ${BACKUP_PATH}"
fi
