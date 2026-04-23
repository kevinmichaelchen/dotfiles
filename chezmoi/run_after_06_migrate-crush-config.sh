#!/usr/bin/env bash
# Move the legacy Crush config out of the runtime data path when it still
# matches the old static chezmoi-managed file.

set -euo pipefail

# Crush now reads config from ~/.config/crush/crush.json. This legacy path under
# ~/.local/share is app data, so only move it aside when it still looks exactly
# like the old static config we previously managed with chezmoi.
LEGACY_PATH="${HOME}/.local/share/crush/crush.json"
BACKUP_PATH="${LEGACY_PATH}.chezmoi-legacy-config.bak"

if [[ ! -f "${LEGACY_PATH}" ]]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Warning: jq not found, skipping Crush legacy config migration"
  exit 0
fi

# Guard the migration aggressively: if this file has started accumulating
# runtime/session state, leave it alone. We only back it up when it still
# matches the old provider/model/context config shape that used to live here.
if jq -e '
  .["$schema"] == "https://charm.land/crush.json" and
  .providers["openrouter-fireworks"].type == "openai-compat" and
  .providers.openrouter.type == "openai-compat" and
  .models.large.model == "moonshotai/kimi-k2.6" and
  .models.small.model == "google/gemini-2.5-flash-lite" and
  .options.context_paths == ["CLAUDE.md", "AGENTS.md", ".cursorrules"]
' "${LEGACY_PATH}" >/dev/null 2>&1; then
  # Preserve the old file for inspection/recovery instead of deleting it.
  if [[ -e "${BACKUP_PATH}" ]]; then
    BACKUP_PATH="${BACKUP_PATH}.$(date +%Y%m%d%H%M%S)"
  fi

  mv "${LEGACY_PATH}" "${BACKUP_PATH}"
  echo "Moved legacy Crush config to ${BACKUP_PATH}"
fi
