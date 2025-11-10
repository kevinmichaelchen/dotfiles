#!/bin/sh
# Testcontainers configuration for Podman
# Shell-agnostic - can be sourced by bash, zsh, etc.

# Update Testcontainers configuration with current Podman socket path
update_testcontainers_config() {
  if command -v podman >/dev/null 2>&1; then
    local socket_path
    socket_path=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)

    if [ -n "$socket_path" ]; then
      echo "docker.host=unix://${socket_path}" > "$HOME/.testcontainers.properties"
    fi
  fi
}

# Update configuration on shell startup
update_testcontainers_config
