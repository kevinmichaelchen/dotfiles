#!/usr/bin/env bash
# Install ~/.agents/skills entries declared in skills-lock.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCK_FILE="${REPO_DIR}/skills-lock.json"
TARGET_DIR="${AGENTS_SKILLS_DIR:-${HOME}/.agents/skills}"
TARGET_EXPLICIT=0
FORCE=0
PRUNE=0
SCAN=1

# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage: sync.sh [--force] [--prune] [--no-scan] [--target DIR]

Installs lock-managed upstream skills into ~/.agents/skills.

Options:
  --force    Reinstall even when the installed marker matches the lock entry.
  --prune    Remove previously managed skills that are no longer in the lock.
  --no-scan  Skip SkillSpector scanning before install.
  --target   Install into DIR. Required for targets outside ~/.agents/skills.
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
    --target)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --target" >&2
        exit 2
      fi
      TARGET_DIR="$2"
      TARGET_EXPLICIT=1
      shift
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

resolve_target_path() {
  local path="$1"
  local candidate suffix base_real

  if [[ -z "${path}" ]]; then
    echo "Refusing empty skill target" >&2
    return 1
  fi

  if [[ "${path}" != /* ]]; then
    path="${PWD}/${path}"
  fi

  if [[ -e "${path}" && ! -d "${path}" ]]; then
    echo "Refusing skill target that is not a directory: ${path}" >&2
    return 1
  fi

  candidate="${path}"
  suffix=""

  while [[ ! -e "${candidate}" && "${candidate}" != "/" ]]; do
    suffix="/$(basename "${candidate}")${suffix}"
    candidate="$(dirname "${candidate}")"
  done

  if [[ ! -d "${candidate}" ]]; then
    echo "Refusing skill target with non-directory ancestor: ${path}" >&2
    return 1
  fi

  base_real="$(cd "${candidate}" && pwd -P)"
  printf '%s%s\n' "${base_real}" "${suffix}"
}

guard_target_dir() {
  local requested="$1"
  local explicit="$2"
  local home_real allowed_root target_real

  home_real="$(cd "${HOME}" && pwd -P)"
  allowed_root="$(resolve_target_path "${HOME}/.agents/skills")"
  target_real="$(resolve_target_path "${requested}")"

  case "${target_real}" in
    ""|"/"|"${home_real}")
      echo "Refusing unsafe skill target: ${target_real}" >&2
      return 1
      ;;
  esac

  if [[ "${explicit}" -ne 1 ]]; then
    case "${target_real}" in
      "${allowed_root}"|"${allowed_root}/"*)
        ;;
      *)
        echo "Refusing skill target outside ${allowed_root}: ${target_real}" >&2
        echo "Pass --target ${requested} to opt into a non-default target." >&2
        return 1
        ;;
    esac
  fi

  printf '%s\n' "${target_real}"
}

TARGET_DIR="$(guard_target_dir "${TARGET_DIR}" "${TARGET_EXPLICIT}")"

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
