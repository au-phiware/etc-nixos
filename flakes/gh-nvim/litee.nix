{ config, lib, pkgs, ... }:

let
  cfg = config.gh-nvim.litee;

  litee-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "litee.nvim";
    version = "unstable-2024-01-01";
    src = pkgs.fetchFromGitHub {
      owner = "ldelossa";
      repo = "litee.nvim";
      rev = "main";
      hash = "sha256-LVbaNAi4AeBqSg7f5sOCn2I7ihpyL5A8R4KkCYHKSOU=";
    };
    meta.homepage = "https://github.com/ldelossa/litee.nvim";
  };

  # Convert nix attrs to lua table string
  toLuaObject = lib.generators.toLua {};
in
{
  options.gh-nvim.litee = {
    enable = lib.mkEnableOption "litee.nvim library for IDE-lite experiences";

    package = lib.mkOption {
      type = lib.types.package;
      default = litee-nvim;
      description = "The litee.nvim plugin package to use";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Options passed to require('litee.lib').setup()";
      example = lib.literalExpression ''
        {
          tree = {
            icon_set = "codicons";
          };
          panel = {
            orientation = "left";
            panel_size = 30;
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nixvim.extraPlugins = [ cfg.package ];
    programs.nixvim.extraConfigLua = ''
      require('litee.lib').setup(${toLuaObject cfg.settings})
    '';
  };
}
