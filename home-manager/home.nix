{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "kchen";
  home.homeDirectory = "/Users/kchen";

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
    bun
    chezmoi
    eza
    fd
    gh
    git
    git-town
    gum
    jq
    pnpm
    podman
    podman-compose
    ripgrep
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
  #  /etc/profiles/per-user/kchen/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
    VOLTA_HOME = "$HOME/.volta";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Starship prompt - just enable it, config is in Chezmoi
  programs.starship.enable = true;

  # Zsh - let Chezmoi manage the config file
  programs.zsh.enable = false;  # We'll manage zsh config via Chezmoi
  
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
    hmu = "nix flake update ~/dotfiles/home-manager && home-manager switch --flake ~/dotfiles/home-manager";
    hme = "cd ~/dotfiles/home-manager && $EDITOR home.nix";
    
    # Chezmoi aliases
    cm = "chezmoi";
    cma = "chezmoi apply";
    cmd = "chezmoi diff";
    cme = "chezmoi edit";
    cmu = "chezmoi update";
  };
}
