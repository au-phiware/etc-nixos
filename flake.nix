{
  description = "au-phiware's flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    home-manager-stable.url = "github:nix-community/home-manager/release-25.05";
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";

    flake-utils.url = "github:numtide/flake-utils";

    envfs.url = "github:Mic92/envfs";
    envfs.inputs.nixpkgs.follows = "nixpkgs-stable";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs-stable";

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    #home-manager-unstable.url = "github:nix-community/home-manager";
    #home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    #nixpkgs-bleeding = { url = "github:nixos/nixpkgs/master"; };

    #rust-overlay.url = "github:oxalica/rust-overlay";
    #rust-overlay.inputs.nixpkgs.follows = "nixpkgs-stable";

    nixlib.url = "github:nix-community/nixpkgs.lib";

    #pulse.url = "path:/home/corin/src/github.com/creativecreature/pulse";
    #pulse.inputs.nixpkgs.follows = "nixpkgs-stable";

    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.nixpkgs.follows = "nixpkgs-unstable";
    niri.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    anyrun.url = "github:Kirottu/anyrun";
    anyrun.inputs.nixpkgs.follows = "nixpkgs-unstable";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    #claude-desktop = {
    #  url = "path:/home/corin/src/github.com/k3d3/claude-desktop-linux-flake";
    #  inputs.nixpkgs.follows = "nixpkgs-unstable";
    #  inputs.flake-utils.follows = "flake-utils";
    #};
  };

  outputs = {self, ...} @ inputs: let
    nixlib = inputs.nixlib.outputs.lib;

    supportedSystems = [
      "x86_64-linux"
    ];

    forAllSystems = nixlib.genAttrs supportedSystems;
  in {
    overlays.default = import ./overlay.nix;
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

    legacyPackages = forAllSystems (system:
      import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.self.overlays.default
          # inputs.rust-overlay.overlays.default
        ];
      });

    nixosConfigurations = {
      euler = let
        system = "x86_64-linux";

        nixpkgs-stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              inputs.self.overlays.default
              # inputs.rust-overlay.overlays.default
            ];
          };
        nixpkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      in inputs.nixpkgs-stable.lib.nixosSystem rec {
        inherit system;

        modules = [
          (import ./euler.nix)
          inputs.home-manager-stable.nixosModules.home-manager
          inputs.niri.nixosModules.niri
          # inputs.stylix.nixosModules.stylix
          {
            nixpkgs.overlays = [
              inputs.self.overlays.default
              inputs.niri.overlays.niri
              # inputs.anyrun.overlays.default
              # inputs.rust-overlay.overlays.default
              #(final: prev: {
              #  vimPlugins = prev.vimPlugins // {
              #    pulseVimPlugin = inputs.pulse.packages.${system}.pulseVimPlugin;
              #  };
              #})
              #(final: prev: {
              #  claude-desktop-unfree = nixpkgs-unstable.callPackage (inputs.claude-desktop + "/pkgs/claude-desktop.nix") {
              #    inherit (inputs.claude-desktop.packages.${prev.system}) patchy-cnb;
              #  };
              #})
            ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              pkgs = nixpkgs-stable;
            };
            # home-manager.sharedModules = [
            #   inputs.niri.homeModules.stylix
            # ];
          }
          #inputs.pulse.nixosModules.${system}.default
        ];

        specialArgs = {
          inherit inputs;
          unstable = nixpkgs-unstable;
          stable = nixpkgs-stable;
          #bleeding = (import inputs.nixpkgs-bleeding { inherit system; config.allowUnfree = true; });
        };
      };
    };
  };
}
