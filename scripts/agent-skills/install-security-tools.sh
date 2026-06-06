#!/usr/bin/env bash
# Install agent-skill security tooling that is not fully handled by Mise.

set -euo pipefail

SKILLSPECTOR_SPEC="${SKILLSPECTOR_SPEC:-git+https://github.com/NVIDIA/skillspector.git@main}"

if ! command -v pipx >/dev/null 2>&1; then
  echo "Missing required tool: pipx" >&2
  exit 1
fi

if command -v skillspector >/dev/null 2>&1; then
  echo "SkillSpector is already installed: $(command -v skillspector)"
else
  echo "Installing SkillSpector from ${SKILLSPECTOR_SPEC}"
  pipx install "${SKILLSPECTOR_SPEC}"
fi
