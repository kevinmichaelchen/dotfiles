{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  # These will be set by the Darwin configuration dynamically

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    awscli2
    bat
    bun
    chezmoi
    d2
    delta
    eza
    fd
    gh
    git
    git-town
    _1password-cli
    glow
    go
    gum
    jira-cli-go
    jq
    pnpm
    podman
    podman-compose
    krunkit  # GPU-accelerated VM provider for Podman on Apple Silicon
    postgresql.pg_config
    python3
    python3Packages.pip
    ripgrep
    tokei
    uv
    volta
    yq
    zoxide
    
    # Rust development tools
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt
    
    # Custom Rust package from crates.io/GitHub
    (rustPlatform.buildRustPackage rec {
      pname = "git-grab";
      version = "3.0.0";
      
      src = fetchFromGitHub {
        owner = "wezm";
        repo = "git-grab";
        rev = version;
        hash = "sha256-MsJDfmWU6LyK7M0LjYQufIpKmtS4f2hgo4Yi/x1HsrU=";
      };
      
      cargoHash = "sha256-nJBgKrgfmLzHVZzVUah2vS+fjNzJp5fNMzzsFu6roug=";
      
      doCheck = false;  # Tests fail in sandbox (pbcopy not available)
      
      meta = with lib; {
        description = "Clone a git repository into a standard location organised by domain and path";
        homepage = "https://github.com/wezm/git-grab";
        license = licenses.mit;
      };
    })
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/<username>/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
    VOLTA_HOME = "$HOME/.volta";
    GRAB_HOME = "$HOME/dev";
    # Use libkrun for GPU-accelerated Podman VMs on Apple Silicon
    CONTAINERS_MACHINE_PROVIDER = "libkrun";
  };

  # Declaratively manage Volta packages
  # These are installed/updated on every `home-manager switch`
  home.activation.voltaPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export VOLTA_HOME="$HOME/.volta"
    export PATH="$VOLTA_HOME/bin:$PATH"
    if command -v volta &> /dev/null; then
      volta install node@24 || true
      volta install @anthropic-ai/claude-code@latest || true
      volta install @beads/bd@latest || true
      volta install @charmland/crush@latest || true
      volta install @google/gemini-cli@latest || true
      volta install @intellectronica/ruler@latest || true
    fi
  '';

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Starship prompt - just enable it, config is in Chezmoi
  programs.starship.enable = true;

  # Zsh - home-manager manages packages and sources Chezmoi config
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # Installs zsh-autosuggestions package
    syntaxHighlighting.enable = true;  # Installs zsh-syntax-highlighting package
    enableCompletion = true;            # Sets up completion system

    # Source the Chezmoi-managed custom configuration
    initContent = ''
      # Load custom zsh configuration managed by Chezmoi
      if [[ -f ~/.config/zsh/custom.zsh ]]; then
        source ~/.config/zsh/custom.zsh
      fi
    '';
  };

  # fzf - fuzzy finder with shell integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Use fd for faster file search
    defaultCommand = "fd --type f --hidden --strip-cwd-prefix --exclude .git";

    # CTRL-T: File and directory selection with preview
    fileWidgetCommand = "fd --type f --type d --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetOptions = [
      "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
      "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
    ];

    # ALT-C: Directory navigation with tree preview
    changeDirWidgetCommand = "fd --type d --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];

    # CTRL-R: Command history search
    historyWidgetOptions = [
      "--preview 'echo {}' --preview-window up:3:hidden:wrap"
      "--bind 'ctrl-/:toggle-preview'"
    ];

    # Default options for all fzf invocations
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--info=inline"
    ];
  };

  # Shell aliases for all shells (stable, rarely change)
  home.shellAliases = {
    # eza aliases (ls replacement)
    ls = "eza --icons --group-directories-first";
    ll = "eza --icons --group-directories-first -la";
    l = "eza --icons --group-directories-first -l";
    la = "eza --icons --group-directories-first -a";
    lt = "eza --icons --group-directories-first --tree --level=2";
    tree = "eza --tree";
    
    # ripgrep with path sorting
    rg = "rg --sort path";
    
    # Dotfile management
    dot = "cd ~/dotfiles";
    dot-update = "cd ~/dotfiles && ./scripts/update.sh";
    
    # Home-Manager aliases
    hm = "home-manager switch --flake ~/dotfiles/home-manager";
    hmu = "(cd ~/dotfiles/home-manager && nix flake update) && home-manager switch --flake ~/dotfiles/home-manager";
    hme = "cd ~/dotfiles/home-manager && $EDITOR home.nix";
    
    # Chezmoi aliases (use ~/dotfiles/chezmoi as source)
    cm = "chezmoi --source=$HOME/dotfiles/chezmoi";
    cma = "chezmoi apply --source=$HOME/dotfiles/chezmoi";
    cmd = "chezmoi diff --source=$HOME/dotfiles/chezmoi";
    cme = "chezmoi edit --source=$HOME/dotfiles/chezmoi";
    cmu = "chezmoi update --source=$HOME/dotfiles/chezmoi";
  };
}
