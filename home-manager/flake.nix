{
  description = "Home Manager configuration of kchen";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "1password-cli"
        ];
      };

      # Helper function to create a home-manager configuration for a specific user
      mkHomeConfig = username: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
          {
            home.username = username;
            home.homeDirectory = "/Users/${username}";
          }
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    in
    {
      homeConfigurations."kchen" = mkHomeConfig "kchen";
      homeConfigurations."kevinchen" = mkHomeConfig "kevinchen";
    };
}
