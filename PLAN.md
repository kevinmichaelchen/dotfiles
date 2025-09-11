# Unified Dotfiles Management Plan
## Home-Manager + Chezmoi Integration Strategy

### Overview
This document outlines the plan for managing system configuration using both Home-Manager (Nix) and Chezmoi, leveraging the strengths of each tool for an optimal development workflow.

## Tool Responsibilities

### Home-Manager (Nix)
**Purpose**: Package management and system-level configuration
- Installing and managing software packages
- System environment variables
- Shell enablement and basic configuration
- Program activation (enabling services/tools)
- Reproducible system environments

### Chezmoi
**Purpose**: Personal dotfile management and synchronization
- Personal configuration files (vim, git, ssh, etc.)
- Machine-specific templating
- Secret management (passwords, API keys)
- Quick iteration on config changes
- Cross-platform dotfile synchronization

## Recommended Directory Structure

```
~/dotfiles/                     # Main repository
├── README.md                   # Documentation
├── .git/                       # Single git repository
│
├── home-manager/               # Nix/Home-Manager configs
│   ├── flake.nix              # Flake definition
│   ├── flake.lock             # Locked dependencies
│   ├── home.nix               # Main configuration
│   └── modules/               # Modular configurations
│       ├── packages.nix       # Package lists
│       ├── shell.nix          # Shell configuration
│       └── dev-tools.nix      # Development environments
│
├── chezmoi/                    # Chezmoi source directory
│   ├── .chezmoi.toml.tmpl     # Chezmoi config template
│   ├── .chezmoiignore         # Files to ignore
│   ├── dot_gitconfig.tmpl     # Git config template
│   ├── dot_zshrc.local        # Personal shell config
│   ├── dot_vimrc              # Vim configuration
│   └── private_dot_ssh/       # SSH configs (encrypted)
│       └── config.tmpl
│
└── scripts/                    # Helper scripts
    ├── bootstrap.sh           # Initial machine setup
    ├── update.sh              # Update both systems
    └── backup.sh              # Backup configurations
```

## Configuration Files

### `.chezmoiignore`
```
# Ignore Nix/Home-Manager files
home-manager/
scripts/
.git/
README.md
PLAN.md
*.nix
flake.lock
```

### Updated `home.nix` Integration
```nix
# Install chezmoi via Nix
home.packages = with pkgs; [
  chezmoi
  # ... other packages
];

# Source Chezmoi-managed personal configs
programs.zsh.initExtra = ''
  # Load personal configuration managed by Chezmoi
  [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
'';

# Unified management aliases
home.shellAliases = {
  # Dotfile management
  dot = "cd ~/dotfiles";
  dot-update = "cd ~/dotfiles && ./scripts/update.sh";
  
  # Individual tool commands
  hm = "home-manager switch --flake ~/dotfiles/home-manager";
  hmu = "nix flake update ~/dotfiles/home-manager && home-manager switch --flake ~/dotfiles/home-manager";
  cm = "chezmoi";
  cma = "chezmoi apply";
  cmd = "chezmoi diff";
  cme = "chezmoi edit";
  cmu = "chezmoi update";
};
```

## Migration Steps

### Phase 1: Setup New Structure
1. Create new directory structure at `~/dotfiles/`
   ```bash
   mkdir -p ~/dotfiles/{home-manager,chezmoi,scripts}
   cd ~/dotfiles
   git init
   ```

2. Move existing Home-Manager configuration
   ```bash
   cp -r ~/.config/home-manager/* ~/dotfiles/home-manager/
   ```

3. Update flake paths in aliases and scripts

### Phase 2: Initialize Chezmoi
1. Install chezmoi (via Home-Manager)
   ```nix
   home.packages = with pkgs; [ chezmoi ];
   ```

2. Initialize with custom source path
   ```bash
   chezmoi init --source ~/dotfiles/chezmoi
   ```

3. Add existing dotfiles to Chezmoi
   ```bash
   chezmoi add ~/.gitconfig
   chezmoi add ~/.vimrc
   # Add other personal configs
   ```

### Phase 3: Create Helper Scripts

#### `scripts/bootstrap.sh`
```bash
#!/usr/bin/env bash
# Bootstrap script for new machines

echo "Setting up unified dotfiles..."

# Clone repository
git clone https://github.com/username/dotfiles.git ~/dotfiles

# Install Nix (if not present)
if ! command -v nix &> /dev/null; then
    sh <(curl -L https://nixos.org/nix/install)
fi

# Install Home-Manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

# Apply Home-Manager configuration
home-manager switch --flake ~/dotfiles/home-manager

# Initialize Chezmoi
chezmoi init --source ~/dotfiles/chezmoi --apply

echo "Setup complete!"
```

#### `scripts/update.sh`
```bash
#!/usr/bin/env bash
# Update both Home-Manager and Chezmoi

echo "Updating dotfiles..."

# Update git repository
git pull

# Update and apply Home-Manager
echo "Updating Home-Manager..."
nix flake update ~/dotfiles/home-manager
home-manager switch --flake ~/dotfiles/home-manager

# Update Chezmoi
echo "Updating Chezmoi configs..."
chezmoi apply

echo "Update complete!"
```

### Phase 4: Cleanup
1. Archive old `~/.config/home-manager/` directory
2. Update any remaining references to old paths
3. Commit everything to git
4. Test on a fresh machine or VM

## Workflow Examples

### Daily Development
```bash
# Edit a personal config file
cme ~/.vimrc          # Opens in editor via Chezmoi
cma                   # Apply changes instantly

# Add a new package
cd ~/dotfiles/home-manager
vim home.nix          # Add package to list
hm                    # Apply Home-Manager changes
```

### New Machine Setup
```bash
# One-liner setup
curl -L https://your-bootstrap-url.sh | bash

# Or manual
git clone https://github.com/you/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh
```

### Syncing Changes
```bash
# After making local changes
cd ~/dotfiles
git add -A
git commit -m "Update configs"
git push

# On another machine
dot-update  # Pulls and applies everything
```

## Best Practices

### What Goes Where?

**Home-Manager**:
- Package installations
- System-wide environment variables
- Shell/terminal emulator enablement
- Programming language toolchains
- System services

**Chezmoi**:
- Personal aliases and functions
- Editor configurations
- Git user settings
- SSH configurations
- API keys and secrets (encrypted)
- Machine-specific configurations

### Guidelines
1. **Frequent edits** → Chezmoi (fast iteration)
2. **System packages** → Home-Manager (reproducible)
3. **Secrets** → Chezmoi with encryption
4. **Cross-platform** → Chezmoi templates
5. **Complex setup** → Home-Manager modules

### Version Control
- Single repository for both tools
- Clear commit messages indicating which tool
- Tag releases for stable configurations
- Branch for experimental changes

## Benefits of This Approach

1. **Speed**: Edit configs without Nix rebuilds
2. **Flexibility**: Use the right tool for each task
3. **Reproducibility**: Nix ensures consistent packages
4. **Portability**: Works across different machines/OSes
5. **Security**: Proper secret management with Chezmoi
6. **Simplicity**: Clear separation of concerns
7. **Version Control**: Everything in one repository

## Future Enhancements

- [ ] Add machine-specific Home-Manager profiles
- [ ] Implement automated testing for configurations
- [ ] Create GitHub Actions for validation
- [ ] Add more sophisticated backup strategies
- [ ] Document team sharing workflows