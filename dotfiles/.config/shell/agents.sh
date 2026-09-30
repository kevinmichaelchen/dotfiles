# shellcheck shell=sh
# Load app-native config layers; keep machine-local files owned by the apps.
export OPENCODE_CONFIG="${OPENCODE_CONFIG:-$HOME/.config/opencode/dotfiles.json}"

codex() {
  # An explicitly selected profile should override the shell default.
  for _codex_argument in "$@"; do
    case "$_codex_argument" in
      -p|--profile|--profile=*|-p?*)
        command codex "$@"
        return
        ;;
    esac
  done
  command codex --profile dotfiles "$@"
}

claude() {
  # Management subcommands operate on Claude's own persisted configuration.
  case "${1:-}" in
    mcp|auth|plugin|plugins|install|update|upgrade|doctor|completion|setup-token|agents|attach|logs|project|respawn|rm|stop|kill|import|ultrareview)
      command claude "$@"
      return
      ;;
  esac
  # Honor an explicit MCP configuration or an explicit end-of-options marker.
  for _claude_argument in "$@"; do
    case "$_claude_argument" in
      --mcp-config|--mcp-config=*|--strict-mcp-config|--)
        command claude "$@"
        return
        ;;
    esac
  done
  # Append the variadic option so it does not consume the user's prompt.
  command claude "$@" --mcp-config "$HOME/.config/claude/mcp.json"
}
