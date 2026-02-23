{
  description = "Corin's NixOS flake - gauss workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, niri, stylix, nixvim, flake-utils, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          self.overlays.default
          niri.overlays.niri
        ];
      };

      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      theme = import ./theme.nix;
    in
    {
      overlays.default = import ./overlays.nix;

      nixosConfigurations.gauss = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs unstable theme;
        };

        modules = [
          ./hosts/gauss.nix
          niri.nixosModules.niri
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              self.overlays.default
              niri.overlays.niri
            ];

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs unstable theme; };
              sharedModules = [ nixvim.homeManagerModules.nixvim ];
              users.corin = import ./home/desktop.nix;
            };
          }
        ];
      };

      # Development shell for working on this flake
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixpkgs-fmt
          nil
        ];
      };
    };
}
