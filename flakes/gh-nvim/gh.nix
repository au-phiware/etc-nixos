{ config, lib, pkgs, ... }:

let
  cfg = config.gh-nvim.gh;

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

  # Convert nix attrs to lua table string
  toLuaObject = lib.generators.toLua {};
in
{
  options.gh-nvim.gh = {
    enable = lib.mkEnableOption "gh.nvim for GitHub integration in Neovim";

    package = lib.mkOption {
      type = lib.types.package;
      default = gh-nvim;
      description = "The gh.nvim plugin package to use";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Options passed to require('litee.gh').setup()";
      example = lib.literalExpression ''
        {
          jump_mode = "invoking";
          map_resize_keys = false;
          disable_keymaps = false;
          icon_set = "default";
          git_buffer_completion = true;
          keymaps = {
            open = "<CR>";
            expand = "zo";
            collapse = "zc";
            goto_issue = "gd";
            details = "d";
            submit_comment = "<C-s>";
            actions = "<C-a>";
            resolve_thread = "<C-r>";
            goto_web = "gx";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Automatically enable litee dependency
    gh-nvim.litee.enable = lib.mkDefault true;

    programs.nixvim.extraPlugins = [ cfg.package ];

    programs.nixvim.extraConfigLua = lib.mkAfter ''
      require('litee.gh').setup(${toLuaObject cfg.settings})
    '';
  };
}
