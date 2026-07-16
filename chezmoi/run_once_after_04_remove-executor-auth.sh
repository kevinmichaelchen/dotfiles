#!/bin/sh
# Remove the superseded machine-local bearer file from the PR's interim design.

set -eu

rm -f "$HOME/.config/shell/executor-auth.sh"
