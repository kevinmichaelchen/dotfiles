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
