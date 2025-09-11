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
    homebrew-crc = {
      url = "github:cfergeau/homebrew-crc";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask, homebrew-crc }: {
    darwinConfigurations."MLJLWV4J4TLC" = nix-darwin.lib.darwinSystem {
      modules = [
        ./configuration.nix
        
        # Home Manager module
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.kchen = import ../home-manager/home.nix;
        }
        
        # nix-homebrew module
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            # Apple Silicon uses a different prefix
            enableRosetta = true;
            user = "kchen";
            
            # Declaratively manage taps
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "cfergeau/homebrew-crc" = homebrew-crc;
            };
            
            mutableTaps = false;
          };
        }
      ];
    };
  };
}