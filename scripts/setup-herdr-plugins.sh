#!/usr/bin/env bash
# Register Mise-owned sources/runtimes; never rewrite declarative config.
set -euo pipefail
sources="$HOME/.local/share/herdr-plugin-sources"
for plugin in projects reviewr annotate; do
  test -f "$sources/$plugin/herdr-plugin.toml" || {
    echo "Missing $plugin source: run mise bootstrap repos apply first" >&2
    exit 1
  }
done

link_binary() {
  local binary destination
  binary="$(mise which "$1")"
  destination="$2"
  test -x "$binary"
  if [[ -e "$destination" && ! -L "$destination" ]]; then
    echo "Refusing to replace unmanaged binary: $destination" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$destination")"
  ln -sfn "$binary" "$destination"
}
# Preserve the paths expected by the exact upstream manifests and wrappers.
link_binary herdr-projects "$sources/projects/target/release/herdr-projects"
link_binary herdr-reviewr "$sources/reviewr/bin/herdr-reviewr"
link_binary herdr-annotate "$sources/annotate/bin/herdr-annotate.exe"
link_binary plannotator-tui "$sources/annotate/bin/plannotator-tui.exe"

herdr config check
for plugin in projects reviewr annotate; do
  herdr plugin link "$sources/$plugin" --enabled
done
# Native hook registration is journaled by Projects. Sidebar, profiles,
# policy and the shared autoproject skill are already declared through Mise.
herdr-projects configure --clients claude,codex --hooks-only
herdr plugin list
