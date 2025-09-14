{
  description = "Kevin's nix-darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    
    # Homebrew tap repositories
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    # Helper function to create a Darwin configuration for a specific user
    mkDarwinConfig = username: nix-darwin.lib.darwinSystem {
      modules = [
        ./configuration.nix

        # User-specific configuration
        {
          system.primaryUser = username;
          users.users.${username} = {
            name = username;
            home = "/Users/${username}";
          };
        }

        # Home Manager module
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = { ... }: {
            imports = [ ../home-manager/home.nix ];
            home.username = username;
            home.homeDirectory = "/Users/${username}";
          };
        }

        # nix-homebrew module
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            # Apple Silicon uses a different prefix
            enableRosetta = true;
            user = username;

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;

            # Declaratively manage taps
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

            mutableTaps = false;
          };
        }
      ];
    };
  in {
    # Configuration for machines with user "kevinchen"
    darwinConfigurations."kevinchen" = mkDarwinConfig "kevinchen";

    # Configuration for machines with user "kchen"
    darwinConfigurations."kchen" = mkDarwinConfig "kchen";

    # Default points to kevinchen for this machine
    darwinConfigurations."default" = mkDarwinConfig "kevinchen";
  };
}