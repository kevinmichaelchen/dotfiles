#!/bin/sh
# Docker and container-related configuration
# Shell-agnostic - can be sourced by bash, zsh, etc.

# Testcontainers configuration for Podman
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
