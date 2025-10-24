#!/bin/sh
# Python configuration
# Shell-agnostic - can be sourced by bash, zsh, etc.

# Add Python user site packages to PATH
# This allows pip install --user packages to be found
if command -v python3 &> /dev/null; then
  PYTHON_USER_BIN="$(python3 -c 'import site; print(site.USER_BASE)')/bin"
  [[ ":$PATH:" != *":$PYTHON_USER_BIN:"* ]] && export PATH="$PATH:$PYTHON_USER_BIN"
fi
