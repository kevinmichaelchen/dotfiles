#!/usr/bin/env bash
# Keep Claude skill entries as symlinks to the canonical ~/.agents/skills tree.

set -euo pipefail

AGENTS_DIR="${HOME}/.agents/skills"
CLAUDE_DIR="${HOME}/.claude/skills"
CANONICAL_PREFIX="../../.agents/skills"

mkdir -p "${AGENTS_DIR}" "${CLAUDE_DIR}"

sync_claude_skill() {
  local entry="$1"
  local name target desired link_target resolved

  name="$(basename "${entry}")"
  target="${AGENTS_DIR}/${name}"
  desired="${CANONICAL_PREFIX}/${name}"

  if [[ -L "${entry}" ]]; then
    link_target="$(readlink "${entry}")"

    if [[ "${link_target}" == "${desired}" && -e "${target}" ]]; then
      return 0
    fi

    if [[ -e "${entry}" ]]; then
      if [[ ! -e "${target}" && ! -L "${target}" ]]; then
        resolved="$(realpath "${entry}")"
        if [[ -d "${resolved}" ]]; then
          ditto "${resolved}" "${target}"
          echo "Copied ${resolved} to ${target}"
        else
          cp -p "${resolved}" "${target}"
          echo "Copied ${resolved} to ${target}"
        fi
      fi

      rm "${entry}"
      ln -s "${desired}" "${entry}"
      echo "Re-linked ${entry} -> ${desired}"
      return 0
    fi

    if [[ -e "${target}" ]]; then
      rm "${entry}"
      ln -s "${desired}" "${entry}"
      echo "Fixed stale symlink ${entry} -> ${desired}"
      return 0
    fi

    rm "${entry}"
    echo "Removed broken Claude skill link ${entry}"
    return 0
  fi

  if [[ -e "${entry}" ]]; then
    if [[ -e "${target}" || -L "${target}" ]]; then
      echo "Warning: ${entry} exists but ${target} already exists; leaving it untouched"
      return 0
    fi

    mv "${entry}" "${target}"
    ln -s "${desired}" "${entry}"
    echo "Moved ${entry} to ${target} and linked it back"
  fi
}

while IFS= read -r -d '' entry; do
  sync_claude_skill "${entry}"
done < <(find "${CLAUDE_DIR}" -mindepth 1 -maxdepth 1 -print0)

while IFS= read -r -d '' target; do
  name="$(basename "${target}")"
  entry="${CLAUDE_DIR}/${name}"

  if [[ ! -e "${entry}" && ! -L "${entry}" ]]; then
    ln -s "${CANONICAL_PREFIX}/${name}" "${entry}"
    echo "Linked ${entry} -> ${CANONICAL_PREFIX}/${name}"
  fi
done < <(find "${AGENTS_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)
