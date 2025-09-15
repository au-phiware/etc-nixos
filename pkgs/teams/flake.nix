{
  description = "au-phiware's flake";

  inputs = {
    nixpkgs = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nixlib.url = "github:nix-community/nixpkgs.lib";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    nixlib = inputs.nixlib.outputs.lib;

    supportedSystems = [
      "x86_64-linux"
    ];

    forAllSystems = nixlib.genAttrs supportedSystems;
  in {
    defaultPackage = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {allowUnfree = true;};
      };
    in
      pkgs.callPackage ./default.nix {inherit (pkgs);});
  };
}
