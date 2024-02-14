{
  description = "au-phiware's flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixpkgs-stable = { url = "github:nixos/nixpkgs/nixos-23.11"; };
    home-manager-stable.url = "github:nix-community/home-manager/release-23.11";
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";

    envfs.url = "github:Mic92/envfs";
    envfs.inputs.nixpkgs.follows = "nixpkgs-stable";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs-stable";

    nixpkgs-unstable = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    nixpkgs-bleeding = { url = "github:nixos/nixpkgs/master"; };

    # rust-overlay.url = "github:oxalica/rust-overlay";
    # rust-overlay.inputs.nixpkgs.follows = "nixpkgs-stable";

    nixlib.url = "github:nix-community/nixpkgs.lib";
  };

  outputs = { self, ... }@inputs:
    let
      nixlib = inputs.nixlib.outputs.lib;

      supportedSystems = [
        "x86_64-linux"
      ];

      forAllSystems = nixlib.genAttrs supportedSystems;

    in {

      overlays.default = (import ./overlay.nix);
      # overlays.rust-nightly = (import overlays/rust-nightly.nix);

      # checks = forAllSystems (system:
      #   let
      #     checkArgs = {
      #       pkgs = inputs.nixpkgs-stable.legacyPackages.${system};
      #       inherit self;
      #     };
      #   in
      #   {
      #     example = import ./tests/example.nix checkArgs;
      #     edge = import ./tests/edge.nix checkArgs;
      #   }
      # );

      devShells = forAllSystems (system: {

        # rust =
        #   let
        #     pkgs = import inputs.nixpkgs-stable { overlays = [ inputs.rust-overlay.overlays.default ]; inherit system; };
        #   in
        #   (import ./shells/rust {
        #     inherit pkgs inputs;
        #   });

        # rust-nightly =
        #   let
        #     pkgs = import inputs.nixpkgs-stable { overlays = [ inputs.rust-overlay.overlays.default ]; inherit system; };
        #   in
        #   (import ./shells/rust/nightly.nix {
        #     inherit pkgs inputs;
        #   });

        # pynode =
        #   let
        #     pkgs = import inputs.nixpkgs-stable {
        #       inherit system;
        #       config.allowUnfree = true;
        #       overlays = [
        #         (import ./shells/pynode/cypress-overlay.nix)
        #         (import ./shells/pynode/pyppeteer-overlay.nix)
        #       ];
        #     };
        #   in
        #   (import ./shells/pynode {
        #     inherit pkgs inputs;
        #   });

      });

      legacyPackages = forAllSystems (system: import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.self.overlays.default
          # inputs.rust-overlay.overlays.default
        ];
      });

      nixosConfigurations = {

        euler = inputs.nixpkgs-stable.lib.nixosSystem {

          modules = [
            (import ./euler.nix)
            inputs.home-manager-stable.nixosModules.home-manager
            {
              nixpkgs.overlays = [
                inputs.self.overlays.default
                # inputs.rust-overlay.overlays.default
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];

          system = "x86_64-linux";

          specialArgs = {
            inherit inputs;
            unstable = (import inputs.nixpkgs-unstable { system = "x86_64-linux"; config.allowUnfree = true; });
            stable = (import inputs.nixpkgs-stable { system = "x86_64-linux"; config.allowUnfree = true; });
            bleeding = (import inputs.nixpkgs-bleeding { system = "x86_64-linux"; config.allowUnfree = true; });
          };
        };

      };
  };
}
