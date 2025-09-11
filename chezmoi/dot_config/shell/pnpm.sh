#!/bin/sh
# pnpm aliases based on Oh-My-Zsh pnpm plugin
# Shell-agnostic - can be sourced by bash, zsh, etc.

# General aliases
alias pn='pnpm'
alias pnx='pnpm dlx'
alias pni='pnpm init'

# Install aliases
alias pna='pnpm add'
alias pnad='pnpm add --save-dev'
alias pnag='pnpm add --global'
alias pnap='pnpm add --save-peer'

# Remove/uninstall aliases
alias pnrm='pnpm remove'
alias pnrmg='pnpm remove --global'
alias pnun='pnpm uninstall'

# Run scripts aliases
alias pnr='pnpm run'
alias pnrd='pnpm run dev'
alias pnrb='pnpm run build'
alias pnrs='pnpm run start'
alias pnrt='pnpm run test'
alias pnrtc='pnpm run test --coverage'
alias pnrl='pnpm run lint'
alias pnrp='pnpm run preview'
alias pnrdoc='pnpm run doc'

# List aliases
alias pnls='pnpm list'
alias pnls1='pnpm list --depth=1'
alias pnlsg='pnpm list --global'
alias pnlsg1='pnpm list --global --depth=1'

# Install/update aliases
alias pni='pnpm install'
alias pnif='pnpm install --frozen-lockfile'
alias pnup='pnpm update'
alias pnupl='pnpm update --latest'
alias pnupg='pnpm update --global'
alias pnupi='pnpm update --interactive'
alias pnupil='pnpm update --interactive --latest'

# Audit aliases
alias pnau='pnpm audit'
alias pnauf='pnpm audit --fix'

# Other useful aliases
alias pnout='pnpm outdated'
alias pnoutg='pnpm outdated --global'
alias pnwhy='pnpm why'
alias pnst='pnpm store status'
alias pnstp='pnpm store prune'
alias pnck='pnpm check'

# Workspace aliases
alias pnw='pnpm --workspace-root'
alias pnwi='pnpm --workspace-root install'
alias pnwr='pnpm --workspace-root run'
alias pnwrb='pnpm --workspace-root run build'
alias pnwrt='pnpm --workspace-root run test'
alias pnf='pnpm --filter'

# Publishing aliases
alias pnpub='pnpm publish'
alias pnpk='pnpm pack'

# Cache management
alias pncc='pnpm cache clean'
alias pncv='pnpm cache verify'

# Config aliases
alias pncg='pnpm config get'
alias pncs='pnpm config set'
alias pncl='pnpm config list'

# Info aliases
alias pninfo='pnpm info'
alias pnv='pnpm --version'

# Create aliases
alias pncr='pnpm create'

# Execute aliases
alias pnex='pnpm exec'

# Link aliases
alias pnln='pnpm link'
alias pnlng='pnpm link --global'
alias pnuln='pnpm unlink'

# Patch aliases
alias pnpatch='pnpm patch'
alias pnpatchc='pnpm patch-commit'

# Store aliases
alias pnsa='pnpm store add'
alias pnsp='pnpm store path'
alias pnss='pnpm store status'

# Setup alias
alias pnsetup='pnpm setup'

# Import alias
alias pnimp='pnpm import'

# Rebuild alias
alias pnrb='pnpm rebuild'

# Dedupe alias
alias pndd='pnpm dedupe'

# Env alias
alias pnenv='pnpm env'

# Licenses alias
alias pnlic='pnpm licenses list'