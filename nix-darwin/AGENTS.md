# nix-darwin/AGENTS.md

## OVERVIEW

macOS system configuration using **nix-darwin** with embedded **Home-Manager**.
This directory configures system-level settings, Homebrew integration, and
bootstraps the user environment.

## FILES

| File                | Purpose                                       |
| ------------------- | --------------------------------------------- |
| `flake.nix`         | Multi-user flake with `mkDarwinConfig` helper |
| `configuration.nix` | System defaults, Homebrew brews/casks         |

## ARCHITECTURE

```
flake.nix
├── mkDarwinConfig(username)     # Helper for multi-user support
│   ├── configuration.nix        # System config
│   ├── home-manager module      # Embeds HM, imports ../home-manager/home.nix
│   └── nix-homebrew module      # Declarative Homebrew
└── darwinConfigurations
    ├── kevinchen                 # Personal machine
    ├── kchen                     # Work machine
    └── default → kevinchen
```

## PACKAGE PLACEMENT GUIDE

| Belongs Here (Homebrew)   | Belongs in home.nix | Belongs in Mise         |
| ------------------------- | ------------------- | ----------------------- |
| macOS GUI apps (casks)    | CLI tools           | Dev runtimes (node, go) |
| Keg-only formulae (libpq) | Shell programs      | Language toolchains     |
| Apps needing code signing | User packages       | cargo:\*/npm:\* tools   |

## WHY HOMEBREW FOR SOME APPS

Apps requiring **code signing**, **notarization**, or **app bundles** cannot be
built by Nix on macOS. Examples:

- **Ghostty**: Requires universal binary + app bundle (see flake.nix comments)
- **Most GUI apps**: Need proper .app structure for Finder/Dock integration

Use `homebrew.casks` for these. Nix handles everything else.

## KEY CONVENTIONS

### mutableTaps = true

**Required.** When `false`, nix-darwin tries to exclusively control Homebrew
taps and fails with errors like:

```
Error: Refusing to untap homebrew/cask because it contains installed formulae
```

### Multi-User Pattern

The `mkDarwinConfig` helper in `flake.nix` creates per-user configurations:

```nix
mkDarwinConfig = username: nix-darwin.lib.darwinSystem {
  modules = [
    ./configuration.nix
    { system.primaryUser = username; }
    # ... home-manager, nix-homebrew
  ];
};
```

Build with: `darwin-rebuild switch --flake .#kevinchen` (or `#kchen`,
`#default`)

### Determinate Nix

We use Determinate's Nix installer, so `nix.enable = false` in configuration.nix
to avoid conflicts with nix-darwin's Nix management.

## ANTI-PATTERNS

| Don't                            | Why                            | Do Instead                     |
| -------------------------------- | ------------------------------ | ------------------------------ |
| Add user packages here           | System config, not user        | Add to `home-manager/home.nix` |
| Hardcode username in config      | Breaks multi-user              | Use `mkDarwinConfig` pattern   |
| Set `mutableTaps = false`        | Breaks cask installations      | Keep `true`                    |
| Add dev tools (node, rust, etc.) | Mise manages runtimes          | Add to `mise/config.toml`      |
| Use `nix.enable = true`          | Conflicts with Determinate Nix | Keep `false`                   |

## COMMANDS

```bash
# Apply configuration (from anywhere)
darwin-rebuild switch --flake ~/dotfiles/nix-darwin#default

# Or use alias
dr

# Edit configuration.nix
dre

# View what would change
darwin-rebuild build --flake ~/dotfiles/nix-darwin#default
```

## ADDING PACKAGES

### Homebrew Formula (CLI tool, keg-only, or macOS-specific)

```nix
# configuration.nix
homebrew.brews = [
  "libpq"    # Example: keg-only PostgreSQL client
  "ripgrep"
];
```

### Homebrew Cask (GUI application)

```nix
# configuration.nix
homebrew.casks = [
  "ghostty"  # Example: terminal requiring app bundle
];
```

### System Default

```nix
# configuration.nix
system.defaults.dock.autohide = true;
system.defaults.finder.ShowPathbar = true;
```

## TROUBLESHOOTING

### "Refusing to untap homebrew/cask"

Ensure `mutableTaps = true` in the nix-homebrew module.

### Homebrew not finding packages

Run `brew update` manually, or wait for next `darwin-rebuild switch` (autoUpdate
is enabled).

### Home-manager changes not applying

Changes to `home.nix` require `darwin-rebuild switch`, not just `chezmoi apply`.
