# Dotfiles

A unified approach to managing system configuration using Nix/Home-Manager for reproducible package management and Chezmoi for personal dotfile synchronization.

## 📋 Overview

This repository combines the best of both worlds:
- **Nix/Home-Manager**: Declarative, reproducible system package management
- **Chezmoi**: Flexible, templated personal configuration management

## 🗂️ Directory Structure

```
~/dotfiles/
├── home-manager/           # Nix/Home-Manager configurations
│   ├── flake.nix          # Flake definition for reproducible builds
│   ├── flake.lock         # Locked dependencies
│   └── home.nix           # Main Home-Manager configuration
│
├── chezmoi/               # Chezmoi-managed personal configs
│   ├── .chezmoiignore     # Files for Chezmoi to ignore
│   ├── dot_gitconfig      # Git configuration
│   ├── dot_vimrc          # Vim configuration
│   ├── dot_zshrc          # Zsh configuration
│   └── dot_config/        # .config directory files
│       ├── shell/
│       │   └── git.sh     # Shell-agnostic git aliases
│       └── starship.toml  # Starship prompt configuration
│
└── scripts/               # Helper automation scripts
    ├── bootstrap.sh       # Initial machine setup
    └── update.sh          # Update both systems
```

## 🛠️ Technologies

### Nix
[Nix](https://nixos.org/) is a powerful package manager that makes package management reliable and reproducible. It provides:
- **Declarative configuration**: Define your entire system setup in code
- **Reproducibility**: Same configuration produces identical environments
- **Rollbacks**: Easy reversion to previous configurations
- **No dependency hell**: Each package gets its exact dependencies

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
- curl

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
1. Install Nix using the [Determinate Systems](https://determinate.systems/) installer
2. Set up Home-Manager
3. Apply the Nix configuration (installing all packages)
4. Initialize Chezmoi with your personal configs

### Daily Usage

#### Update Everything
```bash
dot-update  # Pulls latest changes and applies both Home-Manager and Chezmoi configs
```

#### Manage Packages (via Home-Manager)
```bash
# Edit package list
hme  # Opens home.nix in your editor

# Apply changes
hm   # Rebuild and switch to new configuration

# Update and apply
hmu  # Update flake.lock and rebuild
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
- Installs Nix (if not present) using Determinate Systems installer
- Sets up Home-Manager
- Applies the full configuration
- Initializes Chezmoi

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
- Enabling shells and tools
- Stable shell aliases (that rarely change)
- Development tools (rustc, cargo, volta, etc.)

**Chezmoi** manages:
- Shell configuration (.zshrc, starship.toml)
- Personal configuration files (.gitconfig, .vimrc)
- Git aliases (via shell-agnostic git.sh)
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
- `cm` - Chezmoi command
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