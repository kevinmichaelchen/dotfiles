{ config, pkgs, ... }:

{
  # Disable nix-darwin's Nix management since we're using Determinate
  nix.enable = false;

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;
  
  # Set Git commit hash for darwin-version (if available)
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # REQUIRED: Set the primary user for system defaults and homebrew
  system.primaryUser = "kchen";

  # User configuration
  users.users.kchen = {
    name = "kchen";
    home = "/Users/kchen";
  };

  # Homebrew configuration
  homebrew = {
    enable = true;
    
    # Automatically update Homebrew and upgrade packages on activation
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Cleanup old versions
      cleanup = "zap";
    };
    
    # Taps
    taps = [
      "cfergeau/crc"
    ];
    
    # Brews (formulae)
    brews = [
      "vfkit"  # Required for podman on macOS
    ];
    
    # Casks (GUI applications)
    casks = [
      # Add any GUI apps you want managed by Homebrew here
    ];
  };

  # System defaults
  system.defaults = {
    dock = {
      autohide = true;
      orientation = "left";
      show-recents = false;
    };
    
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    
    NSGlobalDomain = {
      AppleKeyboardUIMode = 3;  # Full keyboard access
      ApplePressAndHoldEnabled = false;  # Disable press-and-hold for keys
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };
}