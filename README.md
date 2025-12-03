# Dotfiles

A unified approach to managing system configuration using Nix/Home-Manager for reproducible package management and Chezmoi for personal dotfile synchronization.

## 📋 Overview

This repository combines the best of both worlds:
- **Nix/Home-Manager**: Declarative, reproducible system package management
- **Chezmoi**: Flexible, templated personal configuration management

## 🗂️ Directory Structure

```
~/dotfiles/
├── nix-darwin/            # macOS system configuration (includes Home-Manager)
│   ├── flake.nix          # Flake with nix-darwin, Home-Manager, and nix-homebrew
│   └── configuration.nix  # System-level macOS configuration
│
├── home-manager/          # Standalone Home-Manager (for non-macOS systems)
│   ├── flake.nix          # Flake definition for reproducible builds
│   ├── flake.lock         # Locked dependencies
│   └── home.nix           # User packages and configuration
│
├── chezmoi/               # Chezmoi-managed personal configs
│   ├── .chezmoiignore     # Files for Chezmoi to ignore
│   ├── dot_gitconfig      # Git configuration
│   ├── dot_vimrc          # Vim configuration
│   └── dot_config/        # .config directory files
│       ├── git/
│       │   └── kevinmichaelchen  # Personal git config for GitHub repos
│       ├── shell/
│       │   ├── bat.sh     # bat aliases and functions (cat, batdiff, help)
│       │   ├── git.sh     # Shell-agnostic git aliases
│       │   ├── pnpm.sh    # PNPM configuration
│       │   ├── python.sh  # Python/UV configuration
│       │   └── zed.sh     # Zed editor configuration
│       ├── starship.toml  # Starship prompt configuration
│       └── zsh/
│           └── custom.zsh # Zsh configuration
│
└── scripts/               # Helper automation scripts
    ├── bootstrap.sh       # Initial machine setup
    └── update.sh          # Update both systems
```

## 🏗️ Architecture

### macOS Systems
On macOS, we use **nix-darwin** as the primary configuration manager with:
- **nix-darwin**: System-level configuration (dock, Finder, keyboard settings)
- **nix-homebrew**: Declarative Homebrew management (for macOS-only tools like vfkit)
- **Home-Manager**: Runs as a module within nix-darwin for user packages
- **Chezmoi**: Personal dotfile management

### Non-macOS Systems (Linux)
On Linux, we use:
- **Home-Manager**: Standalone user environment management
- **Chezmoi**: Personal dotfile management

## 🛠️ Technologies

### Nix
[Nix](https://nixos.org/) is a powerful package manager that makes package management reliable and reproducible. It provides:
- **Declarative configuration**: Define your entire system setup in code
- **Reproducibility**: Same configuration produces identical environments
- **Rollbacks**: Easy reversion to previous configurations
- **No dependency hell**: Each package gets its exact dependencies

### nix-darwin
[nix-darwin](https://github.com/LnL7/nix-darwin) provides declarative macOS system configuration:
- System preferences and defaults
- Homebrew package management
- Service management
- Integration with Home-Manager

### Home-Manager
[Home-Manager](https://github.com/nix-community/home-manager) is a Nix-based tool for managing user environments. It handles:
- Installing and configuring user packages
- Managing dotfiles through Nix
- Setting up development environments
- Configuring shells and terminal applications

### Chezmoi
[Chezmoi](https://www.chezmoi.io/) is a sophisticated dotfile manager that provides:
- **Templating**: Machine-specific configurations
- **Encryption**: Secure secret management
- **Version control**: Git-based tracking
- **Cross-platform**: Works on Linux, macOS, and Windows

## 🚀 Getting Started

### Prerequisites
- Git
- [Nix](https://docs.determinate.systems/) (install via Determinate Systems)

### Initial Setup

For a new machine, run:

```bash
curl -L https://raw.githubusercontent.com/kevinmichaelchen/dotfiles/main/scripts/bootstrap.sh | bash
```

Or manually:

```bash
# Clone the repository
git clone https://github.com/kevinmichaelchen/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the bootstrap script
./scripts/bootstrap.sh
```

The bootstrap script will:
1. Clone the dotfiles repository (if not already present)
2. Verify Nix is installed (exits with instructions if not)
3. Display clear next steps for completing the setup

After running the bootstrap script, you'll need to:
1. Apply the system configuration (command provided by the script)
2. Initialize Chezmoi after packages are installed

### Onboarding

After the initial setup, complete these steps to enable 1Password CLI integration:

1. **Download 1Password for macOS**
   - Download from [1Password.com](https://1password.com/downloads/mac/) or the Mac App Store

2. **Enable 1Password CLI integration**
   - Open 1Password → Settings → Developer
   - Enable "Integrate with 1Password CLI"

3. **Apply Chezmoi configuration**
   ```bash
   chezmoi apply --source=$HOME/dotfiles/chezmoi
   ```

   Note: After applying Home-Manager, you can use the `cma` alias instead.

### Daily Usage

#### Update Everything
```bash
# On macOS
darwin-rebuild switch --flake ~/dotfiles/nix-darwin#default

# On Linux (standalone Home-Manager)
nix run home-manager -- switch --flake ~/dotfiles/home-manager

# Or use the shortcut (works on any system)
dot-update  # Pulls latest changes and applies appropriate configuration
```

#### Manage Packages
```bash
# Edit package list
hme  # Opens home.nix in your editor

# Apply changes (macOS)
darwin-rebuild switch --flake ~/dotfiles/nix-darwin#default

# Apply changes (Linux)
nix run home-manager -- switch --flake ~/dotfiles/home-manager
```

#### Manage Personal Configs (via Chezmoi)
```bash
# Edit a config file
cme ~/.vimrc  # Opens in editor through Chezmoi

# View changes
cmd  # Show diff of pending changes

# Apply changes
cma  # Apply all Chezmoi-managed configs

# Add a new config file
chezmoi add ~/.some-config
```

## 📝 Scripts

### `bootstrap.sh`
Initial setup script for new machines. It:
- Checks for and clones the dotfiles repository if needed
- Installs Nix (if not present) using Determinate Systems installer
- Provides colorful output with clear next steps
- Shows the exact commands to run for your system (macOS vs Linux)

Note: The script prepares your system but doesn't run commands requiring sudo. You'll need to run the provided commands manually to complete the setup.

### `update.sh`
Daily update script that:
- Pulls latest changes from git
- Updates and applies Home-Manager configuration
- Applies Chezmoi configuration changes

## 🎯 Philosophy

Following the ["use Nix less"](https://jade.fyi/blog/use-nix-less/) principle for better iteration speed and simplicity.

### What Goes Where?

**Home-Manager** manages:
- Package installations (ripgrep, fd, chezmoi, zsh, starship, etc.)
- Enabling shells and tools (zsh with autosuggestions, syntax highlighting)
- Stable shell aliases (that rarely change)
- Development tools (rustc, cargo, volta, etc.)
- The base .zshrc file (for proper plugin initialization)

**Chezmoi** manages:
- Shell configuration (~/.config/zsh/custom.zsh, starship.toml)
- Personal configuration files (.gitconfig, .vimrc)
- Shell aliases and functions (via shell-agnostic scripts: bat.sh, git.sh, pnpm.sh, python.sh, zed.sh)
- Machine-specific settings
- Secrets and API keys (encrypted)
- Quick-iteration configs

### Best Practices

1. **Shell configs & prompts** → Edit via Chezmoi for instant application
2. **New software packages** → Add to home.nix for reproducible installation
3. **Frequently edited configs** → Manage with Chezmoi
4. **Stable aliases** → Keep in Home-Manager
5. **Cross-shell compatibility** → Use shared scripts like git.sh

## 🔧 Useful Aliases

The configuration includes these helpful aliases:

- `dot` - Navigate to dotfiles directory
- `dot-update` - Update everything
- `hm` - Apply Home-Manager changes
- `hmu` - Update and apply Home-Manager
- `hme` - Edit Home-Manager config
- `cm` - Chezmoi command (uses ~/dotfiles/chezmoi as source)
- `cma` - Apply Chezmoi changes
- `cmd` - Show Chezmoi diff
- `cme` - Edit file with Chezmoi
- `cmu` - Update Chezmoi

## 🔄 Workflow Examples

### Adding a new package
```bash
hme                    # Edit home.nix
# Add package to the list
hm                     # Apply changes
```

### Modifying personal config
```bash
cme ~/.gitconfig       # Edit via Chezmoi
cma                    # Apply changes
```

### Syncing to another machine
```bash
# On source machine
git add -A
git commit -m "Update configs"
git push

# On target machine
dot-update            # Pull and apply everything
```

## 📚 Resources

- [Nix Documentation](https://nixos.org/learn.html)
- [Home-Manager Manual](https://nix-community.github.io/home-manager/)
- [Chezmoi User Guide](https://www.chezmoi.io/user-guide/command-overview/)
- [Determinate Systems](https://determinate.systems/)

## 📄 License

This repository is for personal configuration management. Feel free to use it as inspiration for your own dotfiles setup!