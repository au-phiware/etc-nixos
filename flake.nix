{
  description = "Corin's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-3.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, nixvim, lix-module }: {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .
    darwinConfigurations."EPZ-K7NT9FJ75L" = darwin.lib.darwinSystem {
      modules = [
        ./darwin.nix
        ./epz.nix
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users."corin.lawson".imports = [
              nixvim.homeManagerModules.nixvim
              ./darwin-home.nix
            ];
          };
        }
        lix-module.nixosModules.default
      ];
    };
  };
}
