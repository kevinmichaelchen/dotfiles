#!/usr/bin/env bash
# Ensure peon-ping Claude hooks are present without clobbering existing settings.

set -euo pipefail

SETTINGS_PATH="${HOME}/.claude/settings.json"
PEON_DIR="${HOME}/.claude/hooks/peon-ping"
PEON_SCRIPT="${PEON_DIR}/peon.sh"
USE_SCRIPT="${PEON_DIR}/scripts/hook-handle-use.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "Warning: jq not found, skipping Claude peon hook sync"
  exit 0
fi

if [[ ! -f "${PEON_SCRIPT}" ]]; then
  echo "Info: peon-ping is not installed at ${PEON_SCRIPT}, skipping Claude hook sync"
  exit 0
fi

mkdir -p "$(dirname "${SETTINGS_PATH}")"
if [[ ! -f "${SETTINGS_PATH}" ]]; then
  echo '{}' > "${SETTINGS_PATH}"
fi

if ! jq empty "${SETTINGS_PATH}" >/dev/null 2>&1; then
  echo "Warning: ${SETTINGS_PATH} is invalid JSON, skipping Claude hook sync"
  exit 0
fi

has_use_script=false
if [[ -f "${USE_SCRIPT}" ]]; then
  has_use_script=true
fi

tmp_file="$(mktemp)"

jq \
  --arg peon "${PEON_SCRIPT}" \
  --arg use "${USE_SCRIPT}" \
  --argjson has_use_script "${has_use_script}" \
  '
  .hooks = (.hooks // {}) |
  ({
    SessionStart: [
      {
        matcher: "",
        hooks: [
          {type: "command", command: $peon, timeout: 10}
        ]
      }
    ],
    SessionEnd: [
      {
        matcher: "",
        hooks: [
          {type: "command", command: $peon, timeout: 10, async: true}
        ]
      }
    ],
    SubagentStart: [
      {
        matcher: "",
        hooks: [
          {type: "command", command: $peon, timeout: 10, async: true}
        ]
      }
    ],
    UserPromptSubmit: (
      [
        {
          matcher: "",
          hooks: [
            {type: "command", command: $peon, timeout: 10, async: true}
          ]
        }
      ] + (
        if $has_use_script then
          [
            {
              matcher: "",
              hooks: [
                {type: "command", command: $use, timeout: 5}
              ]
            }
          ]
        else
          []
        end
      )
    ),
    Stop: [
      {
        matcher: "",
        hooks: [
          {type: "command", command: $peon, timeout: 10, async: true}
        ]
      }
    ],
    Notification: [
      {
        matcher: "",
        hooks: [
          {type: "command", command: $peon, timeout: 10, async: true}
        ]
      }
    ],
    PermissionRequest: [
      {
        matcher: "",
        hooks: [
          {type: "command", command: $peon, timeout: 10, async: true}
        ]
      }
    ],
    PostToolUseFailure: [
      {
        matcher: "Bash",
        hooks: [
          {type: "command", command: $peon, timeout: 10, async: true}
        ]
      }
    ],
    PreCompact: [
      {
        matcher: "",
        hooks: [
          {type: "command", command: $peon, timeout: 10, async: true}
        ]
      }
    ]
  }) as $desired |
  reduce ($desired | to_entries[]) as $event (.;
    .hooks[$event.key] = (.hooks[$event.key] // []) |
    reduce $event.value[] as $entry (.;
      if (.hooks[$event.key] | index($entry)) then . else .hooks[$event.key] += [$entry] end
    )
  )
  ' "${SETTINGS_PATH}" > "${tmp_file}"

mv "${tmp_file}" "${SETTINGS_PATH}"
echo "Synced peon-ping Claude hooks in ${SETTINGS_PATH}"
