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
    homebrew-replicate = {
      url = "github:replicate/homebrew-tap";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask, homebrew-replicate }:
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
              "replicate/homebrew-tap" = homebrew-replicate;
            };

            # IMPORTANT: mutableTaps must be true to avoid errors with casks like ghostty
            # When false, nix-darwin tries to exclusively control taps and will fail with:
            # "Error: Refusing to untap homebrew/cask because it contains installed formulae"
            #
            # Why we use Homebrew for Ghostty instead of Nix:
            # Per https://github.com/ghostty-org/ghostty/discussions/2824, Ghostty cannot
            # be packaged with Nix on macOS due to limited Nix support for building macOS
            # app bundles and the requirement for universal binaries. The Ghostty maintainer
            # recommends using official binary releases (available via Homebrew cask) for
            # macOS users. This pattern applies to many macOS GUI apps that require code
            # signing and notarization.
            mutableTaps = true;
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