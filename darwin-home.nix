{ config, pkgs, lib, primaryUser, ... }: {
  home.username = primaryUser;
  home.homeDirectory = "/Users/${primaryUser}";

  # Enable neovim
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    colorschemes.nightfox.enable = true;
    lsp = {
      servers = {
        bashls.enable = true;
        cue.enable = true;
        #eslint.enable = true;
        gh_actions_ls = {
          enable = true;
          package = pkgs.gh-actions-language-server; # from nixos-npm-ls overlay
        };
        gopls = {
          enable = false;
          config.gopls = {
            staticcheck = true;
            vulncheck = "Imports";
            buildFlags = [ "-tags=customer,integration,e2e,unit" ];
            codelenses = {
              generate = true;
              regenerate_cgo = true;
              run_govulncheck = true;
              tidy = true;
              upgrade_dependency = true;
              vendor = true;
            };
          };
        };
        docker_language_server.enable = true;
        jqls.enable = true;
        jsonls.enable = true;
        marksman.enable = true;
        nixd.enable = true;
        omnisharp.enable = true;
        protols.enable = true;
        #powershell_es.enable = true;
        sqls.enable = true;
        #ts_ls.enable = true;
        typos_lsp.enable = true;
        wasm_language_tools = {
          enable = true;
          package = pkgs.wasm-language-tools;
        };
      };
    };
    plugins = {
      airline = {
        enable = true;
        settings = {
          powerline_fonts = 1;
          section_c = "%f @%n";
        };
      };
      blink-cmp.enable = true;
      blink-cmp-copilot.enable = true;
      blink-cmp.settings = {
        signature.enabled = true;
        keymap.preset = "super-tab";
        sources = {
          default = [ "lsp" "buffer" "path" "snippets" "copilot" ];
          providers = {
            copilot = {
              async = true;
              module = "blink-cmp-copilot";
              name = "copilot";
              score_offset = 100;
            };
          };
        };
        snippets = {
          preset = "luasnip";
          expand.__raw = ''
            function(snippet) require('luasnip').lsp_expand(snippet) end
          '';
          active.__raw = ''
            function(filter)
              if filter and filter.direction then
                return require('luasnip').jumpable(filter.direction)
              end
              return require('luasnip').in_snippet()
            end
          '';
          jump.__raw = ''
            function(direction) require('luasnip').jump(direction) end
          '';
        };
      };
      commentary.enable = true;
      #copilot-chat.enable = true;
      #copilot-lua = {
      #  enable = true;
      #  settings.suggestion.enabled = true;
      #};
      dap.enable = true;
      dap-ui.enable = true;
      easy-dotnet.enable = true;
      emmet.enable = true;
      friendly-snippets.enable = true;
      fugitive.enable = true;
      git-conflict.enable = true;
      goyo.enable = true;
      lspconfig.enable = true;
      lsp-format.enable = true;
      luasnip = {
        enable = true;
        fromVscode = [ { } { paths = "~/.vscode/snippets"; } ];
      };
      markdown-preview.enable = true;
      render-markdown.enable = true;
      #femaco.enable = true;
      nix.enable = true;
      none-ls = {
        enable = true;
        sources = {
          formatting = {
            goimports.enable = true;
            nixfmt.enable = true;
            shfmt.enable = true;
            mdformat = {
              enable = true;
              settings = { extra_args = [ "--wrap" "80" ]; };
            };
          };
        };
      };
      nvim-surround.enable = true;
      #rainbow-delimiters.enable = true;
      repeat.enable = true;
      sleuth.enable = true;
      startify.enable = true;
      toggleterm.enable = true;
      typescript-tools.enable = true;
    };
    extraConfigLua = ''
      vim.o.grepprg = "${pkgs.ripgrep}/bin/rg --vimgrep --smart-case"
      vim.o.grepformat = "%f:%l:%c:%m"
      require("lspconfig").gopls.setup({
        settings = {
          gopls = {
            staticcheck = true,
            vulncheck = "Imports",
            buildFlags = {"-tags=customer,integration,e2e,unit"},
          },
        },
      })
    '';
    globals = { mapleader = " "; };
    keymaps = [
      {
        mode = "n";
        key = "-";
        action = "<cmd>Explore<cr>";
        options.desc = "Open Directory Explorer";
      }
      {
        mode = "n";
        key = "gD";
        action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
        options.desc = "Goto Declaration";
      }
      {
        mode = "n";
        key = "gs";
        action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
        options.desc = "Show Signature";
      }
      {
        mode = "n";
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<cr>";
        options.desc = "Goto Definition";
      }
      {
        mode = "n";
        key = "gi";
        action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
        options.desc = "Goto Implementation";
      }
      {
        mode = "n";
        key = "gr";
        action = "<cmd>lua vim.lsp.buf.references()<cr>";
        options.desc = "Goto References";
      }
      {
        mode = "n";
        key = "gt";
        action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
        options.desc = "Goto Type Definition";
      }
      {
        mode = "n";
        key = "ga";
        action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
        options.desc = "Trigger Code Action";
      }
      {
        mode = "n";
        key = "gn";
        action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
        options.desc = "Goto Next Diagnostic";
      }
      {
        mode = "n";
        key = "gp";
        action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
        options.desc = "Goto Previous Diagnostic";
      }
      {
        mode = "n";
        key = "gu";
        action = "<cmd>lua require('dapui').toggle()<CR>";
        options.desc = "Toggle Dapui";
      }
      {
        mode = "n";
        key = "gb";
        action = "<cmd>lua require('dap').toggle_breakpoint()<CR>";
        options.desc = "Toggle breakpoint";
      }
    ];
  };

  #gh-nvim.gh.enable = true;

  programs.ripgrep = {
    enable = true;
    arguments = [ "--no-require-git" "--hidden" ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    shellAliases = {
      nix-switch =
        "pushd $HOME/src/au-phiware/etc-nixos; darwin-rebuild switch --flake .; popd";
      nix-shell = ''nix-shell --command "$SHELL"'';
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "aws" "git" "per-directory-history" "sudo" "vi-mode" ];
    };

    initContent = lib.mkBefore ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh" ]]; then
        source "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh"
      fi

      complete -C '${pkgs.awscli2}/bin/aws_legacy_completer' aws

      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ${./share/p10k.zsh}
    '';
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # It is sometimes useful to fine-tune packages, for example, by applying
    # overrides. You can do that directly here, just don't forget the
    # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # fonts?
    #(pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # You can also create simple shell scripts directly inside your
    # configuration. For example, this adds a command 'my-hello' to your
    # environment:
    #(pkgs.writeShellScriptBin "my-hello" ''
    #  echo "Hello, ${config.home.username}!"
    #'')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".cvsignore".source = ./share/cvsignore;

    #"Library/Application Support/oterm/config.json".text = ''
    #  {
    #    "mcpServers": {
    #      "brave-search": {
    #        "command": "${pkgs.nodejs_22}/bin/npx",
    #        "args": ["-y", "@modelcontextprotocol/server-brave-search"],
    #        "env": {
    #          "BRAVE_API_KEY": "BSA8adqmh47sQo0jqAEcWAh5owz88VL"
    #        }
    #      },
    #      "git": {
    #        "command": "${pkgs.uv}/bin/uvx",
    #        "args": [
    #          "mcp-server-git",
    #          "--repository", "${config.home.homeDirectory}/src/github.com"
    #        ]
    #      }
    #    },
    #    "theme": "textual-dark",
    #    "splash-screen": false
    #  }
    #'';

    #".claude/settings.json".text = builtins.toJSON
    #  {
    #    env = {
    #      CLAUDE_CODE_ENABLE_TELEMETRY = "0";
    #      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
    #    };
    #    hooks = {
    #      Stop = [
    #        {
    #          matcher = "";
    #          hooks = [
    #            {
    #              type = "command";
    #              command = ''${pkgs.terminal-notifier}/bin/terminal-notifier -message "Claude Code Finished" -sound default'';
    #            }
    #          ];
    #        }
    #      ];
    #      Notification = [
    #        {
    #          matcher = "";
    #          hooks = [
    #            {
    #              type = "command";
    #              command = ''${pkgs.terminal-notifier}/bin/terminal-notifier -message "Claude Code needs permission" -sound Basso'';
    #            }
    #          ];
    #        }
    #      ];
    #    };
    #  };

    #".claude/agents".source = let
    #  wshobsonAgents = pkgs.fetchFromGitHub {
    #    owner = "wshobson";
    #    repo = "agents";
    #    rev = "main";
    #    sha256 = "sha256-ToF06V2xz+DCtQfTv+7V8q/ZJLqnPV7QjiuPOJa9vPc=";
    #    # Filter: include *.md only, except README.md
    #    postFetch = ''
    #      cd $out
    #      ${pkgs.findutils}/bin/find . -type f -not -name '*.md' -delete
    #      rm -f README.md
    #    '';
    #  };
    #in
    #  wshobsonAgents;
    #  #pkgs.runCommand "claude-agents" {} ''
    #  #  ln -s ${wshobsonAgents}/* $out/
    #  #'';

    #".claude/commands".source = let
    #  wshobsonCommands = pkgs.fetchFromGitHub {
    #    owner = "wshobson";
    #    repo = "commands";
    #    rev = "main";
    #    sha256 = "sha256-CwmlK/0SvyHMrkyenNbdmqCJ8HgZADi/mf2BYovK/50=";
    #    # Filter: include *.md only, except README.md
    #    postFetch = ''
    #      cd $out
    #      ${pkgs.findutils}/bin/find . -type f -not -name '*.md' -delete
    #      rm -f README.md
    #    '';
    #  };
    #in
    #  wshobsonCommands;
    #  #pkgs.runCommand "claude-commands" {} ''
    #  #  ln -s ${wshobsonCommands}/* $out/
    #  #'';

    # Install PaperWM.spoon (requires hammerspoon, see https://www.hammerspoon.org/go/)
    ".hammerspoon/Spoons/PaperWM.spoon".source = pkgs.fetchFromGitHub {
      owner = "mogenson";
      repo = "PaperWM.spoon";
      rev = "main";
      sha256 = "sha256-AlE/r4IPvJp9DKhQSChnus7xQJG6lWcqUCE+xe90JTA=";
    };
    ".hammerspoon/init.lua".text = ''
      PaperWM = hs.loadSpoon("PaperWM")
      PaperWM:bindHotkeys({
          -- switch to a new focused window in tiled grid
          focus_left  = {{"alt", "cmd"}, "left"},
          focus_right = {{"alt", "cmd"}, "right"},
          focus_up    = {{"alt", "cmd"}, "up"},
          focus_down  = {{"alt", "cmd"}, "down"},

          -- switch windows by cycling forward/backward
          -- (forward = down or right, backward = up or left)
          focus_prev = {{"alt", "cmd"}, "k"},
          focus_next = {{"alt", "cmd"}, "j"},

          -- move windows around in tiled grid
          swap_left  = {{"alt", "cmd", "shift"}, "left"},
          swap_right = {{"alt", "cmd", "shift"}, "right"},
          swap_up    = {{"alt", "cmd", "shift"}, "up"},
          swap_down  = {{"alt", "cmd", "shift"}, "down"},

          -- alternative: swap entire columns, rather than
          -- individual windows (to be used instead of
          -- swap_left / swap_right bindings)
          -- swap_column_left = {{"alt", "cmd", "shift"}, "left"},
          -- swap_column_right = {{"alt", "cmd", "shift"}, "right"},

          -- position and resize focused window
          center_window        = {{"alt", "cmd"}, "c"},
          full_width           = {{"alt", "cmd"}, "f"},
          cycle_width          = {{"alt", "cmd"}, "r"},
          reverse_cycle_width  = {{"ctrl", "alt", "cmd"}, "r"},
          cycle_height         = {{"alt", "cmd", "shift"}, "r"},
          reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},

          -- increase/decrease width
          increase_width = {{"alt", "cmd"}, "l"},
          decrease_width = {{"alt", "cmd"}, "h"},

          -- move focused window into / out of a column
          slurp_in = {{"alt", "cmd"}, "i"},
          barf_out = {{"alt", "cmd"}, "o"},

          -- move the focused window into / out of the tiling layer
          toggle_floating = {{"alt", "cmd", "shift"}, "escape"},

          -- focus the first / second / etc window in the current space
          focus_window_1 = {{"cmd", "shift"}, "1"},
          focus_window_2 = {{"cmd", "shift"}, "2"},
          focus_window_3 = {{"cmd", "shift"}, "3"},
          focus_window_4 = {{"cmd", "shift"}, "4"},
          focus_window_5 = {{"cmd", "shift"}, "5"},
          focus_window_6 = {{"cmd", "shift"}, "6"},
          focus_window_7 = {{"cmd", "shift"}, "7"},
          focus_window_8 = {{"cmd", "shift"}, "8"},
          focus_window_9 = {{"cmd", "shift"}, "9"},

          -- switch to a new Mission Control space
          switch_space_l = {{"alt", "cmd"}, ","},
          switch_space_r = {{"alt", "cmd"}, "."},
          switch_space_1 = {{"alt", "cmd"}, "1"},
          switch_space_2 = {{"alt", "cmd"}, "2"},
          switch_space_3 = {{"alt", "cmd"}, "3"},
          switch_space_4 = {{"alt", "cmd"}, "4"},
          switch_space_5 = {{"alt", "cmd"}, "5"},
          switch_space_6 = {{"alt", "cmd"}, "6"},
          switch_space_7 = {{"alt", "cmd"}, "7"},
          switch_space_8 = {{"alt", "cmd"}, "8"},
          switch_space_9 = {{"alt", "cmd"}, "9"},

          -- move focused window to a new space and tile
          move_window_1 = {{"alt", "cmd", "shift"}, "1"},
          move_window_2 = {{"alt", "cmd", "shift"}, "2"},
          move_window_3 = {{"alt", "cmd", "shift"}, "3"},
          move_window_4 = {{"alt", "cmd", "shift"}, "4"},
          move_window_5 = {{"alt", "cmd", "shift"}, "5"},
          move_window_6 = {{"alt", "cmd", "shift"}, "6"},
          move_window_7 = {{"alt", "cmd", "shift"}, "7"},
          move_window_8 = {{"alt", "cmd", "shift"}, "8"},
          move_window_9 = {{"alt", "cmd", "shift"}, "9"}
      })
      PaperWM:start();
    '';

    "Library/Application Support/com.mitchellh.ghostty/config".source =
      ./share/ghostty.config;
  };

  home.sessionVariables = {
    NH_FLAKE = "/Users/c.lawson/src/github.com/au-phiware/etc-nixos";
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "Corin Lawson";
        email = "c.lawson@machship.com";
      };
      alias = {
        amend = "commit --amend --signoff";
        wip = "commit --no-verify -m WIP";
        sign = "commit --signoff --gpg-sign";
        fixup = "commit --fixup";
        autosquash = "rebase --interactive --autosquash";
        force-push = "push --force";
        log-all = "log --all --graph --decorate --oneline";
      };
      core = {
        excludesfile = "${./share/cvsignore}";
        #hooksPath = "${config.home.homeDirectory}/.local/share/gitconfig/hooks";
      };
      init = { defaultBranch = "main"; };
      push = { default = "current"; };
      pull = { rebase = true; };
      merge = { conflictStyle = "zdiff3"; };
      diff = { algorithm = "histogram"; };
      commit = {
        template = "${./share/gitconfig/commit-template}";
        verbose = true;
      };
      rebase = { updateRefs = true; };
      rerere = { enabled = true; };
      branch = { autosetupmerge = true; };
      credential = {
        "https://github.com" = {
          helper = [ "" "!${pkgs.gh}/bin/gh auth git-credential" ];
        };
        "https://gist.github.com" = {
          helper = [ "" "!${pkgs.gh}/bin/gh auth git-credential" ];
        };
      };
      magithub = {
        online = false;
        status = {
          includeStatusHeader = false;
          includePullRequestsSection = false;
          includeIssuesSection = false;
        };
      };
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    #options.theme = "Solarized (dark)";
  };

  #programs.jujutsu = {
  #  enable = true;
  #  settings = {
  #    user = {
  #      name = "Corin Lawson";
  #      email = "c.lawson@machship.com";
  #    };
  #    template-aliases = {
  #      default_commit_description = ''
  #        "JJ: If applied, this commit will...

  #        JJ: Why is this change needed?
  #        Prior to this change, 

  #        JJ: How does it address the issue?
  #        This change

  #        JJ: Provide links to any relevant tickets, articles or other resources
  #        "
  #      '';
  #    };
  #    ui = {
  #      default-command = ["status"];
  #      bookmark-list-sort-keys = ["committer-date-"];
  #      movement.edit = true;
  #      pager = ":builtin";
  #      streampager.interface = "quit-if-one-page";
  #    };
  #  };
  #};

  programs.awscli = {
    enable = true;
    settings = {
      "profile AdministratorAccess-907977361606" = {
        sso_session = "devsession";
        sso_account_id = "907977361606";
        sso_role_name = "AdministratorAccess";
        region = "ap-southeast-2";
      };
      "sso-session devsession" = {
        sso_start_url = "https://d-9767a3ea21.awsapps.com/start/#";
        sso_region = "ap-southeast-2";
        sso_registration_scopes = "sso:account:access";
      };
      "profile AdministratorAccess-972583819603" = {
        sso_session = "prodsession";
        sso_account_id = "972583819603";
        sso_role_name = "AdministratorAccess";
        region = "ap-southeast-2";
      };
      "sso-session prodsession" = {
        sso_start_url = "https://d-9767a3ea21.awsapps.com/start/#";
        sso_region = "ap-southeast-2";
        sso_registration_scopes = "sso:account:access";
      };
      "profile AdministratorAccess-338261674645" = {
        sso_session = "ai-dev-session";
        sso_account_id = "338261674645";
        sso_role_name = "AdministratorAccess";
        region = "ap-southeast-2";
      };
      "sso-session ai-dev-session" = {
        sso_start_url = "https://d-9767a3ea21.awsapps.com/start/#";
        sso_region = "ap-southeast-2";
        sso_registration_scopes = "sso:account:access";
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.
}
