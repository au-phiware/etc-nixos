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
    # The coding-agent CLIs (claude-code, github-copilot-cli) come from this
    # second, separately locked copy of nixpkgs-unstable. It moves on its own:
    # the nixpkgs-agents-update daemon in darwin.nix bumps just this input twice
    # a day, so the agents stay current without rebuilding the rest of the system.
    nixpkgs-agents.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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

    # MachShip's shared Claude Code skills. Private repo — fetched as a flake
    # input (not pkgs.fetchFromGitHub) so it authenticates via the GitHub token
    # in ~/.config/nix/access-tokens.conf, which darwin-home.nix writes from the
    # gh CLI keychain on every activation.
    machshipSkills = {
      url = "github:machship/claude-skills";
      flake = false;
    };
    # Same repo, pinned to a branch for skills that have not merged to main yet.
    # Drop it once feat/issue-team-router-skill lands.
    machshipSkillsIssueTeamRouter = {
      url = "github:machship/claude-skills/feat/issue-team-router-skill";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-agents,
      darwin,
      home-manager,
      nixvim,
      chromium,
      #gh-nvim,
      nixos-npm-ls,
      openspec,
      machshipSkills,
      machshipSkillsIssueTeamRouter,
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
                (
                  final: prev:
                  let
                    agents = import nixpkgs-agents {
                      inherit (prev.stdenv.hostPlatform) system;
                      config = { inherit (prev.config) allowUnfreePredicate; };
                    };
                    # nixpkgs trails Claude Code releases by a few days, so
                    # pkgs/claude-code holds the latest upstream release
                    # manifest (refreshed by nixpkgs-agents-update) and wins
                    # whenever it is newer than nixpkgs' own.
                    manifest = prev.lib.importJSON ./pkgs/claude-code/manifest.zst.json;
                  in
                  {
                    inherit (agents) github-copilot-cli;
                    claude-code =
                      if prev.lib.versionOlder agents.claude-code.version manifest.version then
                        agents.claude-code.override { inherit manifest; }
                      else
                        agents.claude-code;
                  }
                )
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
              extraSpecialArgs = {
                inherit
                  primaryUser
                  nixpkgs
                  machshipSkills
                  machshipSkillsIssueTeamRouter
                  ;
              };
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
