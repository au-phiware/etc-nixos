{
  description = "Corin's nix-darwin system flake";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      #url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      # url = "github:nix-community/home-manager/release-25.05";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chromium = {
      url = ./flakes/chromium;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #gh-nvim = {
    #  url = ./flakes/gh-nvim;
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    nixos-npm-ls.url = "github:y3owk1n/nixos-npm-ls";

    openspec.url = "github:Fission-AI/OpenSpec";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      home-manager,
      nixvim,
      chromium,
      #gh-nvim,
      nixos-npm-ls,
      openspec,
      #lix-module,
    }:
    let
      primaryUser = "c.lawson";
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .
      darwinConfigurations."AU-DEV-LPT16" = darwin.lib.darwinSystem {
        specialArgs = {
          inherit primaryUser nixos-npm-ls;
        };
        modules = [
          ./darwin.nix
          (
            { pkgs, ... }:
            {
              nixpkgs.overlays = [
                (final: prev: {
                  chromium = chromium.packages.${pkgs.stdenv.hostPlatform.system}.default;
                })
              ];
            }
          )
          (
            { pkgs, ... }:
            {
              environment.systemPackages = [
                openspec.packages.${pkgs.stdenv.hostPlatform.system}.default
              ];
            }
          )
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit primaryUser; };
              users."c.lawson" = {
                imports = [
                  nixvim.homeModules.nixvim
                  #gh-nvim.nixvimModules.default
                  ./darwin-home.nix
                ];
              };
            };
          }
          #lix-module.nixosModules.default
        ];
      };
    };
}
