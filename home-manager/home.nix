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
    podman
    ripgrep
    jq
    yq
    git-town
    fd
    volta
    bun
    eza
    
    # Rust development tools
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
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

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      
      git_branch = {
        symbol = "🌱 ";
      };
      
      git_status = {
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };
      
      nodejs = {
        symbol = "⬢ ";
      };
      
      python = {
        symbol = "🐍 ";
      };
      
      rust = {
        symbol = "🦀 ";
      };
      
      time = {
        disabled = false;
        format = "🕙[$time]($style) ";
        time_format = "%T";
      };
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      # eza aliases (ls replacement)
      ls = "eza --icons --group-directories-first";
      ll = "eza --icons --group-directories-first -la";
      l = "eza --icons --group-directories-first -l";
      la = "eza --icons --group-directories-first -a";
      lt = "eza --icons --group-directories-first --tree --level=2";
      tree = "eza --tree";
      
      # ripgrep with path sorting
      rg = "rg --sort path";
      
      # home-manager aliases
      hm = "home-manager switch --flake ~/.config/home-manager";
      hmu = "nix flake update ~/.config/home-manager && home-manager switch --flake ~/.config/home-manager";
      hme = "cd ~/.config/home-manager && $EDITOR home.nix";
      
      # git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
    };
    
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
    
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "aws" ];
      theme = "robbyrussell";
    };
    
    initExtra = ''
      # Custom zsh configuration
      export PATH="$HOME/.local/bin:$PATH"
      
      # Better directory navigation
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT
      
      # Better history
      setopt HIST_VERIFY
      setopt HIST_REDUCE_BLANKS
      
      # Enable extended globbing
      setopt EXTENDED_GLOB
      
      # Case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      
      # Volta setup
      export VOLTA_HOME="$HOME/.volta"
      export PATH="$VOLTA_HOME/bin:$PATH"
    '';
  };
}
