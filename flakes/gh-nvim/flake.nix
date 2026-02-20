{
  description = "gh.nvim and litee.nvim plugins for nixvim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];

      flake = {
        nixvimModules = {
          litee = ./litee.nix;
          gh = ./gh.nix;
          default = { imports = [ ./litee.nix ./gh.nix ]; };
        };
      };

      perSystem = { pkgs, ... }: {
        packages = {
          litee-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "litee.nvim";
            version = "unstable-2024-06-07";
            src = pkgs.fetchFromGitHub {
              owner = "ldelossa";
              repo = "litee.nvim";
              rev = "main";
              hash = "sha256-LVbaNAi4AeBqSg7f5sOCn2I7ihpyL5A8R4KkCYHKSOU=";
            };
            meta.homepage = "https://github.com/ldelossa/litee.nvim";
          };

          gh-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "gh.nvim";
            version = "unstable-2025-01-22";
            src = pkgs.fetchFromGitHub {
              owner = "ldelossa";
              repo = "gh.nvim";
              rev = "main";
              hash = "sha256-XI4FVjajin0NM+OaEN+O5vmalPpOB2RII+aOERSzjJA=";
            };
            meta.homepage = "https://github.com/ldelossa/gh.nvim";
          };
        };
      };
    };
}
