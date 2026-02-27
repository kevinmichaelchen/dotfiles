---
name: chezmoi-secret-template
description: Create and maintain secret-backed Chezmoi shell templates in `chezmoi/dot_config/shell/*.sh.tmpl` using 1Password references. Use when adding API tokens or credentials, migrating plaintext shell env vars to templates, validating template rendering, or wiring new secret modules into shell startup.
---

# Chezmoi Secret Template

## Overview
Handle secret-bearing shell configuration using Chezmoi templates and 1Password lookups, without exposing raw secret values in repo files or logs.

## Workflow
1. Identify secret variables and target shell module file.
2. Create or update `chezmoi/dot_config/shell/<name>.sh.tmpl`.
3. Use `onepasswordRead` references instead of literal secret values.
4. Ensure shell module loading is wired in `chezmoi/dot_config/zsh/custom.zsh` when adding a new module.
5. Validate template rendering and provide safe apply commands.

## Template Rules
- Use `.sh.tmpl` for any secret-backed exports.
- Keep non-secret aliases/functions in plain `.sh` files.
- Reference 1Password items using `{{ onepasswordRead "op://..." }}`.
- Avoid printing rendered secrets in command output or summaries.

## Validation Steps
1. Render-check template syntax:
   - `chezmoi execute-template < chezmoi/dot_config/shell/<name>.sh.tmpl`
2. Apply from repo source:
   - `chezmoi apply --source=$HOME/dotfiles/chezmoi`
3. Reload shell session or source the generated file as needed.

## Guardrails
- Never commit plaintext secrets.
- Never move secret-backed exports into `home-manager/home.nix`.
- Keep variable names stable to avoid breaking downstream tooling.
