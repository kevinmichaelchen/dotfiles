#!/usr/bin/env bash
# Update skills-lock.json refs and hashes from upstream sources.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCK_FILE="${REPO_DIR}/skills-lock.json"
SCAN=1
ONLY_SKILLS=()

# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage: update-lock.sh [--skill NAME] [--no-scan]

Resolves each skill's trackRef to the latest GitHub commit, downloads the skill
sourcePath, scans it with SkillSpector, computes its directory hash, and updates
skills-lock.json.

Options:
  --skill NAME  Update one skill. May be passed multiple times.
  --no-scan     Skip SkillSpector scanning before writing the lock.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill)
      ONLY_SKILLS+=("$2")
      shift
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

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

tmp_lock="${tmp_dir}/skills-lock.json"
cp "${LOCK_FILE}" "${tmp_lock}"

should_update_skill() {
  local name="$1" requested

  if [[ "${#ONLY_SKILLS[@]}" -eq 0 ]]; then
    return 0
  fi

  for requested in "${ONLY_SKILLS[@]}"; do
    if [[ "${requested}" == "${name}" ]]; then
      return 0
    fi
  done

  return 1
}

resolve_github_ref() {
  local source="$1"
  local track_ref="$2"

  curl -fsSL "https://api.github.com/repos/${source}/commits/${track_ref}" | jq -r '.sha'
}

update_skill() {
  local name="$1"
  local source="$2"
  local source_type="$3"
  local source_path="$4"
  local track_ref="$5"
  local latest_ref work_dir src_dir computed_hash

  if [[ "${source_type}" != "github" ]]; then
    echo "Skipping ${name}: unsupported sourceType '${source_type}'" >&2
    return 1
  fi

  latest_ref="$(resolve_github_ref "${source}" "${track_ref}")"
  if [[ -z "${latest_ref}" || "${latest_ref}" == "null" ]]; then
    echo "Unable to resolve ${source}@${track_ref}" >&2
    return 1
  fi

  echo "Updating ${name} from ${source}/${source_path}@${track_ref} (${latest_ref})"
  work_dir="${tmp_dir}/${name}"
  rm -rf "${work_dir}"
  mkdir -p "${work_dir}"

  src_dir="$(agent_skills_download_github_source "${source}" "${latest_ref}" "${source_path}" "${work_dir}")"

  if [[ "${SCAN}" -eq 1 ]]; then
    "${SCRIPT_DIR}/scan.sh" "${src_dir}"
  fi

  computed_hash="$(agent_skills_tree_hash "${src_dir}")"

  jq \
    --arg name "${name}" \
    --arg trackRef "${track_ref}" \
    --arg ref "${latest_ref}" \
    --arg computedHash "${computed_hash}" \
    '.skills[$name].trackRef = $trackRef
      | .skills[$name].ref = $ref
      | .skills[$name].computedHash = $computedHash' \
    "${tmp_lock}" > "${tmp_lock}.next"
  mv "${tmp_lock}.next" "${tmp_lock}"
}

while IFS=$'\t' read -r name source source_type source_path ref track_ref; do
  if should_update_skill "${name}"; then
    update_skill "${name}" "${source}" "${source_type}" "${source_path}" "${track_ref:-${ref}}"
  fi
done < <(
  jq -r '.skills | to_entries[] |
    [
      .key,
      .value.source,
      .value.sourceType,
      .value.sourcePath,
      .value.ref,
      (.value.trackRef // .value.ref)
    ] | @tsv' "${LOCK_FILE}"
)

cp "${tmp_lock}" "${LOCK_FILE}"
echo "Updated ${LOCK_FILE}"
