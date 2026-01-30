# Mise Migration Summary

This document tracks the migration of development tools from Nix to Mise.

## Migration Strategy

Tools that are **development/language runtimes** → Migrate to Mise Tools that
are **system-level packages** → Keep in Nix/Homebrew

---

## Tools Migrated to Mise

### Core Language Runtimes

| Tool     | Backend | Old Location | Notes                                                 |
| -------- | ------- | ------------ | ----------------------------------------------------- |
| `python` | core    | home.nix     | Python 3 runtime                                      |
| `go`     | core    | home.nix     | Go language runtime                                   |
| `rust`   | core    | home.nix     | Includes cargo, clippy, rust-analyzer, rustc, rustfmt |
| `node`   | core    | home.nix     | Node.js (pinned to 24)                                |

### Package Managers

| Tool   | Backend | Old Location | Notes                             |
| ------ | ------- | ------------ | --------------------------------- |
| `pnpm` | core    | home.nix     | Node.js package manager           |
| `bun`  | core    | home.nix     | Node.js runtime & package manager |
| `uv`   | aqua    | home.nix     | Python package manager & runner   |

### CLI Tools from Cargo (Rust-based)

| Tool     | Backend | Old Location | Purpose                                    |
| -------- | ------- | ------------ | ------------------------------------------ |
| `bat`    | cargo   | home.nix     | `cat` replacement with syntax highlighting |
| `delta`  | cargo   | home.nix     | Git diff viewer                            |
| `eza`    | cargo   | home.nix     | `ls` replacement with icons                |
| `fd`     | cargo   | home.nix     | `find` replacement                         |
| `glow`   | cargo   | home.nix     | Markdown renderer                          |
| `gum`    | cargo   | home.nix     | Shell prompt building toolkit              |
| `tokei`  | cargo   | home.nix     | Code statistics                            |
| `zoxide` | cargo   | home.nix     | `z` replacement (smart cd)                 |

### CLI Tools from GitHub Releases (Go & other binaries)

| Tool              | Backend | Old Location | Purpose                                    |
| ----------------- | ------- | ------------ | ------------------------------------------ |
| `chezmoi`         | github  | home.nix     | Dotfile management (Go project)            |
| `ghq`             | github  | home.nix     | Repository management (Go project)         |
| `gh` (GitHub CLI) | github  | home.nix     | GitHub command-line interface (Go project) |
| `jq`              | github  | home.nix     | JSON processor                             |

### CLI Tools from Aqua (GitHub Releases with Verification)

| Tool    | Backend | Old Location | Purpose                |
| ------- | ------- | ------------ | ---------------------- |
| `yq`    | aqua    | home.nix     | YAML processor         |
| `d2`    | aqua    | home.nix     | Diagram language       |
| `typst` | aqua    | home.nix     | Typesetting system     |
| `uv`    | aqua    | home.nix     | Python package manager |

### npm Packages

| Tool       | Backend | Old Location | Purpose                |
| ---------- | ------- | ------------ | ---------------------- |
| `wrangler` | npm     | home.nix     | Cloudflare Workers CLI |

### npm Global Packages

Already in mise.toml:

- `@anthropic-ai/claude-code`
- `@charmland/crush`
- `@google/gemini-cli`
- `@intellectronica/ruler`
- `@openai/codex`

---

## Tools Kept in Nix/Homebrew

### System-Level Packages (Not Available in Mise)

| Tool                   | Reason                                      | Location |
| ---------------------- | ------------------------------------------- | -------- |
| `git`                  | macOS system package                        | system   |
| `git-town`             | Advanced git workflows                      | home.nix |
| `_1password-cli`       | CLI for 1Password                           | home.nix |
| `cloudflared`          | Cloudflare tunnel daemon (system service)   | home.nix |
| `podman`               | Container runtime                           | home.nix |
| `podman-compose`       | Docker-compose alternative                  | home.nix |
| `krunkit`              | GPU acceleration for Podman (Apple Silicon) | home.nix |
| `postgresql.pg_config` | PostgreSQL system library                   | home.nix |
| `python3Packages.pip`  | Handled by Python runtime in Mise           | home.nix |
| `sesh`                 | Terminal session manager                    | home.nix |
| `tmux`                 | Terminal multiplexer                        | home.nix |
| `mise`                 | Meta tool (keep in Nix for consistency)     | home.nix |
| `mosh`                 | Remote shell                                | home.nix |

### Tools with Other Management

| Tool      | Management                | Location          |
| --------- | ------------------------- | ----------------- |
| `ripgrep` | Homebrew                  | configuration.nix |
| `fzf`     | home-manager programs.fzf | home.nix          |

---

## Next Steps

1. **Verify the mise.toml configuration** for correctness
2. **Test tool installation**: `mise install`
3. **Remove migrated tools from home.nix**
4. **Rebuild your system**:
   - `nix flake update` (if desired)
   - `home-manager switch`
5. **Verify all tools are accessible**: Run `which <tool>` for each migrated
   tool

---

## Implementation Notes

### Installation

After updating `~/.config/mise/config.toml`, run:

```bash
mise install
```

### Version Pinning

- `latest` uses the most recent release
- You can pin specific versions (e.g., `python = "3.12.0"`)
- For stability in projects, use `.mise.toml` files in project roots

### PATH Integration

Mise automatically manages PATH when activated. Ensure `mise activate` is in
your shell config:

```bash
eval "$(mise activate zsh)"
```

This is already managed via Chezmoi in `~/.config/zsh/custom.zsh` or your shell
initialization.

### Verification

To see which tools would be installed:

```bash
mise trust
mise ls --all
```

To check what will be installed:

```bash
mise install --dry-run
```

---

## Tools to Consider Later

- **awscli2**: Available via aqua (cli/awscli-go is faster) - add if needed
- **jq**: Available via aqua - can replace/supplement current setup
- **jira-cli-go**: Check availability via aqua/github - add if needed
