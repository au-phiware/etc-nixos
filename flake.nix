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
  };

  outputs = inputs@{ self, darwin, home-manager, nixvim, nixpkgs }: {
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
      ];
    };
  };
}
