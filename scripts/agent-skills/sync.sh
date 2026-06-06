#!/usr/bin/env bash
# Install ~/.agents/skills entries declared in skills-lock.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCK_FILE="${REPO_DIR}/skills-lock.json"
TARGET_DIR="${AGENTS_SKILLS_DIR:-${HOME}/.agents/skills}"
FORCE=0
PRUNE=0
SCAN=1

# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage: sync.sh [--force] [--prune] [--no-scan]

Installs lock-managed upstream skills into ~/.agents/skills.

Options:
  --force    Reinstall even when the installed marker matches the lock entry.
  --prune    Remove previously managed skills that are no longer in the lock.
  --no-scan  Skip SkillSpector scanning before install.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
      ;;
    --prune)
      PRUNE=1
      ;;
    --no-scan)
      SCAN=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

agent_skills_require_tools jq curl tar

if [[ "${SCAN}" -eq 1 ]]; then
  agent_skills_require_tools skillspector
fi

if [[ ! -f "${LOCK_FILE}" ]]; then
  echo "Missing lock file: ${LOCK_FILE}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

install_skill() {
  local name="$1"
  local source="$2"
  local source_type="$3"
  local source_path="$4"
  local ref="$5"
  local expected_hash="$6"
  local dest="${TARGET_DIR}/${name}"
  local marker="${dest}/.dotfiles-skill-lock.json"
  local work_dir="${tmp_dir}/${name}"
  local src_dir install_dir actual_hash archive_hash

  if [[ "${source_type}" != "github" ]]; then
    echo "Skipping ${name}: unsupported sourceType '${source_type}'" >&2
    return 1
  fi

  if [[ "${FORCE}" -eq 0 && -f "${marker}" && -f "${dest}/SKILL.md" ]]; then
    if jq -e \
      --arg source "${source}" \
      --arg sourcePath "${source_path}" \
      --arg ref "${ref}" \
      --arg computedHash "${expected_hash}" \
      '.source == $source and .sourcePath == $sourcePath and .ref == $ref and .computedHash == $computedHash' \
      "${marker}" >/dev/null; then
      echo "Skill ${name} is already installed at ${ref}"
      return 0
    fi
  fi

  echo "Installing skill ${name} from ${source}/${source_path}@${ref}"
  rm -rf "${work_dir}"
  mkdir -p "${work_dir}"

  src_dir="$(agent_skills_download_github_source "${source}" "${ref}" "${source_path}" "${work_dir}")"
  actual_hash="$(agent_skills_tree_hash "${src_dir}")"

  if [[ -n "${expected_hash}" && "${actual_hash}" != "${expected_hash}" ]]; then
    echo "Hash mismatch for ${name}: expected ${expected_hash}, got ${actual_hash}" >&2
    return 1
  fi

  if [[ "${SCAN}" -eq 1 ]]; then
    "${SCRIPT_DIR}/scan.sh" "${src_dir}"
  fi

  archive_hash="$(agent_skills_sha256_file "${work_dir}/archive.tar.gz")"
  install_dir="${TARGET_DIR}/.${name}.tmp.$$"
  rm -rf "${install_dir}"
  mkdir -p "${install_dir}"
  cp -R "${src_dir}/." "${install_dir}/"

  jq -n \
    --arg source "${source}" \
    --arg sourceType "${source_type}" \
    --arg sourcePath "${source_path}" \
    --arg ref "${ref}" \
    --arg computedHash "${actual_hash}" \
    --arg archiveSha256 "${archive_hash}" \
    '{
      managedBy: "dotfiles/skills-lock.json",
      source: $source,
      sourceType: $sourceType,
      sourcePath: $sourcePath,
      ref: $ref,
      computedHash: $computedHash,
      archiveSha256: $archiveSha256
    }' > "${install_dir}/.dotfiles-skill-lock.json"

  rm -rf "${dest}"
  mv "${install_dir}" "${dest}"
}

while IFS=$'\t' read -r name source source_type source_path ref expected_hash; do
  install_skill "${name}" "${source}" "${source_type}" "${source_path}" "${ref}" "${expected_hash}"
done < <(
  jq -r '.skills | to_entries[] |
    [
      .key,
      .value.source,
      .value.sourceType,
      .value.sourcePath,
      .value.ref,
      (.value.computedHash // "")
    ] | @tsv' "${LOCK_FILE}"
)

if [[ "${PRUNE}" -eq 1 ]]; then
  while IFS= read -r marker; do
    skill_dir="$(dirname "${marker}")"
    skill_name="$(basename "${skill_dir}")"
    if ! jq -e --arg name "${skill_name}" '.skills[$name]' "${LOCK_FILE}" >/dev/null; then
      echo "Pruning unmanaged lock skill ${skill_name}"
      rm -rf "${skill_dir}"
    fi
  done < <(find "${TARGET_DIR}" -mindepth 2 -maxdepth 2 -name .dotfiles-skill-lock.json -print)
fi

echo "Agent skill sync complete."
