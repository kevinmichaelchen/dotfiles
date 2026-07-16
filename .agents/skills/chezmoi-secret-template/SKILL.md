---
name: chezmoi-secret-template
description: Create and maintain age-encrypted Chezmoi secret files and shell configuration. Use when adding API tokens or credentials, migrating 1Password templates or plaintext values, validating decryption, or wiring secret modules into shell startup.
---

# Chezmoi Secret Template

## Overview
Handle secret-bearing configuration using Chezmoi's age encryption with rage,
without exposing plaintext values or the private identity in the repository or
command output.

## Workflow
1. Identify secret variables and target shell module file.
2. Confirm `~/.config/chezmoi/key.txt` exists and is mode `0600`.
3. Add the target with `chezmoi add --encrypt`; never hand-write ciphertext.
4. Ensure shell module loading is wired in `chezmoi/dot_config/zsh/custom.zsh` when adding a new module.
5. Validate template rendering and provide safe apply commands.

## Template Rules
- Use Chezmoi's encrypted source form for secret-backed exports.
- Keep non-secret aliases/functions in plain `.sh` files.
- Do not add new `onepasswordRead` references; migrate existing ones to age.
- Avoid printing rendered secrets in command output or summaries.

## Validation Steps
1. Confirm Chezmoi can decrypt and verify targets without printing secrets:
   - `chezmoi verify`
2. Apply from repo source:
   - `chezmoi apply --source=$HOME/dotfiles/chezmoi`
3. Reload shell session or source the generated file as needed.

## Guardrails
- Never commit plaintext secrets or `~/.config/chezmoi/key.txt`.
- Never move secret-backed exports into `home-manager/home.nix`.
- Keep variable names stable to avoid breaking downstream tooling.
