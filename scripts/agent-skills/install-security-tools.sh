#!/usr/bin/env bash
# Install agent-skill security tooling that is not fully handled by Mise.

set -euo pipefail

SKILLSPECTOR_SPEC="${SKILLSPECTOR_SPEC:-git+https://github.com/NVIDIA/skillspector.git@main}"
SKILLSPECTOR_PYTHON="${SKILLSPECTOR_PYTHON:-}"

python_is_usable() {
  local python="$1"

  [[ -x "${python}" ]] || return 1

  "${python}" - <<'PY'
import platform
import sys

if sys.platform == "darwin" and not platform.mac_ver()[0]:
    raise SystemExit(1)
PY
}

select_python() {
  local candidate

  if [[ -n "${SKILLSPECTOR_PYTHON}" ]]; then
    if python_is_usable "${SKILLSPECTOR_PYTHON}"; then
      printf '%s\n' "${SKILLSPECTOR_PYTHON}"
      return 0
    fi

    echo "SKILLSPECTOR_PYTHON is not usable: ${SKILLSPECTOR_PYTHON}" >&2
    return 1
  fi

  if command -v mise >/dev/null 2>&1; then
    if candidate="$(mise which python 2>/dev/null)" && python_is_usable "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  fi

  for candidate in "${PIPX_DEFAULT_PYTHON:-}" python3 python; do
    [[ -n "${candidate}" ]] || continue
    if command -v "${candidate}" >/dev/null 2>&1; then
      candidate="$(command -v "${candidate}")"
    fi
    if python_is_usable "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  echo "Could not find a usable Python interpreter for SkillSpector" >&2
  return 1
}

if ! command -v pipx >/dev/null 2>&1; then
  echo "Missing required tool: pipx" >&2
  exit 1
fi

if command -v skillspector >/dev/null 2>&1; then
  echo "SkillSpector is already installed: $(command -v skillspector)"
else
  python="$(select_python)"
  echo "Installing SkillSpector from ${SKILLSPECTOR_SPEC}"
  echo "Using Python interpreter: ${python}"
  pipx install --python "${python}" "${SKILLSPECTOR_SPEC}"
fi
