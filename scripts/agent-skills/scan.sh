#!/usr/bin/env bash
# Scan every agent skill directory with SkillSpector.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TARGET_DIR="${AGENTS_SKILLS_DIR:-${HOME}/.agents/skills}"
SOURCE_DIR="${REPO_DIR}/chezmoi/dot_agents/skills"
REPORT_DIR=""
SCOPE="all"

usage() {
  cat <<'EOF'
Usage: scan.sh [--all|--installed|--source] [--report-dir DIR] [SKILL_DIR...]

Scans each skill directory with SkillSpector static analysis. When explicit
SKILL_DIR arguments are provided, only those directories are scanned.

Scopes:
  --all        Scan installed lock-managed skills and still-vendored skills.
  --installed Scan only ~/.agents/skills.
  --source    Scan only chezmoi/dot_agents/skills.

Options:
  --report-dir DIR  Write one JSON SkillSpector report per skill.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      SCOPE="all"
      ;;
    --installed)
      SCOPE="installed"
      ;;
    --source)
      SCOPE="source"
      ;;
    --report-dir)
      REPORT_DIR="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
  shift
done

if ! command -v skillspector >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Missing required tool: skillspector

Install NVIDIA SkillSpector from https://github.com/NVIDIA/skillspector, then
re-run this command.
EOF
  exit 1
fi

mkdir -p "${REPORT_DIR:-/tmp}"

skill_dirs=()

if [[ $# -gt 0 ]]; then
  skill_dirs=("$@")
else
  if [[ "${SCOPE}" == "all" || "${SCOPE}" == "installed" ]]; then
    if [[ -d "${TARGET_DIR}" ]]; then
      while IFS= read -r dir; do
        skill_dirs+=("${dir}")
      done < <(find "${TARGET_DIR}" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)
    fi
  fi

  if [[ "${SCOPE}" == "all" || "${SCOPE}" == "source" ]]; then
    if [[ -d "${SOURCE_DIR}" ]]; then
      while IFS= read -r dir; do
        skill_dirs+=("${dir}")
      done < <(find "${SOURCE_DIR}" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)
    fi
  fi
fi

scanned=0

for dir in "${skill_dirs[@]}"; do
  if [[ ! -f "${dir}/SKILL.md" ]]; then
    echo "Skipping ${dir}: no SKILL.md" >&2
    continue
  fi

  name="$(basename "${dir}")"
  echo "Scanning skill ${name}"

  if [[ -n "${REPORT_DIR}" ]]; then
    skillspector scan "${dir}" --no-llm --format json --output "${REPORT_DIR}/${name}.skillspector.json"
  else
    skillspector scan "${dir}" --no-llm
  fi

  scanned=$((scanned + 1))
done

if [[ "${scanned}" -eq 0 ]]; then
  echo "No skill directories found to scan." >&2
  exit 1
fi

echo "Scanned ${scanned} skill(s)."
