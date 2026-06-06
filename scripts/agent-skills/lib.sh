#!/usr/bin/env bash

agent_skills_script_dir() {
  cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

agent_skills_repo_dir() {
  local script_dir
  script_dir="$(agent_skills_script_dir)"
  cd "${script_dir}/../.." && pwd
}

agent_skills_sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "Missing required checksum tool: shasum or sha256sum" >&2
    return 1
  fi
}

agent_skills_sha256_stream() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    echo "Missing required checksum tool: shasum or sha256sum" >&2
    return 1
  fi
}

agent_skills_file_mode() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

agent_skills_tree_hash() {
  local dir="$1"

  (
    cd "${dir}"
    while IFS= read -r file; do
      local_hash="$(agent_skills_sha256_file "${file}")"
      printf '%s\t%s\t%s\n' "$(agent_skills_file_mode "${file}")" "${file#./}" "${local_hash}"
    done < <(find . -type f ! -name .dotfiles-skill-lock.json -print | LC_ALL=C sort)
  ) | agent_skills_sha256_stream
}

agent_skills_require_tools() {
  local missing=0 tool

  for tool in "$@"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "Missing required tool: ${tool}" >&2
      missing=1
    fi
  done

  return "${missing}"
}

agent_skills_download_github_source() {
  local source="$1"
  local ref="$2"
  local source_path="$3"
  local work_dir="$4"
  local archive="${work_dir}/archive.tar.gz"
  local extract_dir="${work_dir}/extract"
  local root_dir src_dir

  mkdir -p "${extract_dir}"
  curl -fsSL "https://codeload.github.com/${source}/tar.gz/${ref}" -o "${archive}"
  tar -xzf "${archive}" -C "${extract_dir}"

  root_dir="$(find "${extract_dir}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  src_dir="${root_dir}/${source_path}"

  if [[ ! -d "${src_dir}" ]]; then
    echo "Skill sourcePath not found: ${source_path}" >&2
    return 1
  fi

  if [[ ! -f "${src_dir}/SKILL.md" ]]; then
    echo "Skill has no SKILL.md at sourcePath: ${source_path}" >&2
    return 1
  fi

  printf '%s\n' "${src_dir}"
}
