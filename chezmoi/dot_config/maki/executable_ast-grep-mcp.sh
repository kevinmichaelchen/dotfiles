#!/usr/bin/env bash
# Adapted from https://github.com/tontinton/makiconf/blob/main/ast-grep-mcp.sh
set -euo pipefail

AST_GREP="${ASTGREP_BIN:-ast-grep}"

respond() {
  jq -cn --argjson id "$1" --argjson result "$2" \
    '{jsonrpc:"2.0", id:$id, result:$result}'
}

respond_error() {
  jq -cn --argjson id "$1" --arg message "$2" \
    '{jsonrpc:"2.0", id:$id, error:{code:-32602, message:$message}}'
}

tool_result() {
  jq -cn --argjson id "$1" --arg text "$2" --argjson is_error "$3" \
    '{jsonrpc:"2.0", id:$id, result:{content:[{type:"text", text:$text}], isError:$is_error}}'
}

tools_list() {
  jq -cn '{
    tools: [
      {
        name: "search",
        description: "Find code by AST pattern. $NAME matches one node; $$$NAME matches multiple nodes.",
        inputSchema: {
          type: "object",
          properties: {
            pattern: {type:"string", description:"AST pattern with $NAME or $$$NAME metavariables."},
            language: {type:"string", description:"Source language, such as javascript, typescript, python, rust, go, java, c, or cpp."},
            paths: {type:"array", items:{type:"string"}, description:"Directories or files to search; defaults to the current directory."},
            globs: {type:"array", items:{type:"string"}, description:"Optional glob filters, such as *.ts or !test/**."}
          },
          required: ["pattern", "language"]
        }
      },
      {
        name: "search_and_replace",
        description: "Mutating AST search-and-replace. Preview matches, then update every match using captured metavariables.",
        inputSchema: {
          type: "object",
          properties: {
            pattern: {type:"string", description:"AST pattern to match."},
            rewrite: {type:"string", description:"Replacement using metavariables captured by the pattern."},
            language: {type:"string", description:"Source language."},
            paths: {type:"array", items:{type:"string"}, description:"Directories or files to update; defaults to the current directory."},
            globs: {type:"array", items:{type:"string"}, description:"Optional glob filters."}
          },
          required: ["pattern", "rewrite", "language"]
        }
      }
    ]
  }'
}

handle_tool_call() {
  local id="$1"
  local body="$2"
  local tool_name pattern language rewrite
  tool_name="$(jq -r '.params.name // empty' <<<"$body")"
  pattern="$(jq -r '.params.arguments.pattern // empty' <<<"$body")"
  language="$(jq -r '.params.arguments.language // empty' <<<"$body")"
  rewrite="$(jq -r '.params.arguments.rewrite // empty' <<<"$body")"

  if [[ -z "$pattern" || -z "$language" ]]; then
    tool_result "$id" "Error: pattern and language are required." true
    return
  fi

  local -a common_args preview_args apply_args
  common_args=(run --pattern "$pattern" --lang "$language")

  while IFS= read -r glob; do
    [[ -n "$glob" ]] && common_args+=(--globs "$glob")
  done < <(jq -r '.params.arguments.globs[]?' <<<"$body")

  while IFS= read -r path; do
    [[ -n "$path" ]] && common_args+=("$path")
  done < <(jq -r '.params.arguments.paths[]?' <<<"$body")

  preview_args=("${common_args[@]}" --json=compact)
  if [[ "$tool_name" == "search_and_replace" ]]; then
    if [[ -z "$rewrite" ]]; then
      tool_result "$id" "Error: rewrite is required for search_and_replace." true
      return
    fi
    preview_args+=("--rewrite=$rewrite")
  elif [[ "$tool_name" != "search" ]]; then
    tool_result "$id" "Error: unknown tool $tool_name." true
    return
  fi

  local output exit_code=0
  output="$("$AST_GREP" "${preview_args[@]}" 2>&1)" || exit_code=$?

  if [[ $exit_code -eq 1 || -z "$output" || "$output" == "[]" ]]; then
    tool_result "$id" "No matches found." false
    return
  elif [[ $exit_code -ne 0 ]]; then
    tool_result "$id" "ast-grep error (exit $exit_code): $output" true
    return
  fi

  local count details message
  count="$(jq 'length' <<<"$output")"

  if [[ "$tool_name" == "search_and_replace" ]]; then
    apply_args=("${common_args[@]}" "--rewrite=$rewrite" --update-all)
    local apply_output apply_code=0
    apply_output="$("$AST_GREP" "${apply_args[@]}" 2>&1)" || apply_code=$?
    if [[ $apply_code -ne 0 ]]; then
      tool_result "$id" "ast-grep replacement failed (exit $apply_code): $apply_output" true
      return
    fi
    details="$(jq -r '.[] | "\(.file):\(.range.start.line + 1):\(.range.start.column + 1)\n  matched: \(.text)\n  replacement: \(.replacement // "N/A")"' <<<"$output")"
    printf -v message 'Replaced %s matches.\n\n%s' "$count" "$details"
    tool_result "$id" "$message" false
  else
    details="$(jq -r '.[] | "\(.file):\(.range.start.line + 1):\(.range.start.column + 1)\n  \(.lines | gsub("^\\s+"; "") | gsub("\\n$"; ""))"' <<<"$output")"
    printf -v message 'Found %s matches:\n\n%s' "$count" "$details"
    tool_result "$id" "$message" false
  fi
}

while IFS= read -r line; do
  line="${line%%$'\r'}"
  [[ -z "$line" ]] && continue

  id="$(jq -c '.id // null' <<<"$line")"
  method="$(jq -r '.method // empty' <<<"$line")"

  case "$method" in
    initialize)
      result="$(jq -cn '{
        protocolVersion:"2024-11-05",
        capabilities:{tools:{listChanged:false}},
        serverInfo:{name:"ast-grep", version:"1.0.0"}
      }')"
      respond "$id" "$result"
      ;;
    notifications/initialized)
      ;;
    tools/list)
      respond "$id" "$(tools_list)"
      ;;
    tools/call)
      handle_tool_call "$id" "$line"
      ;;
    ping)
      respond "$id" '{}'
      ;;
    *)
      [[ "$id" != "null" ]] && respond_error "$id" "Method not found"
      ;;
  esac
done
