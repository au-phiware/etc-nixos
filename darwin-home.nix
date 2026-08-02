{
  config,
  pkgs,
  lib,
  primaryUser,
  nixpkgs,
  ...
}:
{
  home.username = primaryUser;
  home.homeDirectory = "/Users/${primaryUser}";

  # Enable neovim
  programs.nixvim = {
    enable = true;
    # Reuse the host (nix-darwin) nixpkgs instance rather than letting nixvim
    # import a second copy from its `follows`-ed source. Silences nixvim's
    # flake-follows warning AND avoids a redundant nixpkgs evaluation.
    nixpkgs.pkgs = pkgs;
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
            #buildFlags = [ "-tags=customer,integration,e2e,unit" ];
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
          default = [
            "lsp"
            "buffer"
            "path"
            "snippets"
            "copilot"
          ];
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
      #git-conflict.enable = true;
      goyo.enable = true;
      lspconfig.enable = true;
      lsp-format.enable = true;
      luasnip = {
        enable = true;
        fromVscode = [
          { }
          { paths = "~/.vscode/snippets"; }
        ];
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
              package = pkgs.mdformat.withPlugins (ps: [ ps.mdformat-gfm ]);
              settings = {
                extra_args = [
                  "--wrap"
                  "80"
                ];
              };
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
    # Syntax highlighting for testscript files (the go-internal/testscript
    # and rsc.io/script dialect: testdata scripts, txtar archives, and the
    # biller's devstack scenarios). Not packaged in nixpkgs' vimPlugins, so
    # built from the pinned source.
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "vim-testscript";
        version = "2025-12-06";
        src = pkgs.fetchFromGitHub {
          owner = "twpayne";
          repo = "vim-testscript";
          rev = "8e3997dbcea23e581276e8d4966c6c0841d5f643";
          sha256 = "sha256-939i/HyOZbdmsEi2UwFOg74ACA8sYdF6nxMu9Ngb5io=";
        };
      })
    ];
    # The plugin's own ftdetect covers */testdata/*.txt and *.txtar; devstack
    # scenario files live under scenarios/<name>/scenario.txt, so map those
    # here as well (keys are Lua patterns).
    filetype.pattern = {
      ".*/scenarios/.*/scenario%.txt" = "testscript";
    };
    extraConfigLua = ''
      vim.o.grepprg = "${pkgs.ripgrep}/bin/rg --vimgrep --smart-case"
      vim.o.grepformat = "%f:%l:%c:%m"
      require("lspconfig").gopls.setup({
        settings = {
          gopls = {
            staticcheck = true,
            vulncheck = "Imports",
          },
        },
      })
    '';
    globals = {
      mapleader = " ";
    };
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
    arguments = [
      "--no-require-git"
      "--hidden"
    ];
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
      nix-switch = "pushd $HOME/src/au-phiware/etc-nixos; darwin-rebuild switch --flake .; popd";
      nix-shell = ''nix-shell --command "$SHELL"'';
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "aws"
        "git"
        "per-directory-history"
        "sudo"
        "vi-mode"
      ];
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
  home.file =
    let
      gstack = pkgs.fetchFromGitHub {
        owner = "garrytan";
        repo = "gstack";
        rev = "main";
        sha256 = "sha256-gZ7aTR0iEW0KUUV7bu3yPniC83wa6uTqXJ7nksVWBJk=";
      };
    in
    {
      ".npmrc".text = ''
        min-release-age=7
      '';

      # Per-user Nix config. Determinate manages /etc/nix/nix.conf, so we can't
      # go through nix-darwin's nix.settings (nix.enable = false). Nix reads
      # ~/.config/nix/nix.conf too, so we own it here and pull the GitHub token
      # from an out-of-repo file written at activation from `gh auth token`.
      # Plain `!include` — Determinate Nix (2.31) rejects the `!include?`
      # optional form as a syntax error. The activation script always writes the
      # token file, and this nix tolerates a missing include target anyway.
      ".config/nix/nix.conf".text = ''
        !include ${config.home.homeDirectory}/.config/nix/access-tokens.conf
      '';

      # Pin the `nixpkgs` flake-registry alias to the exact nixpkgs this system
      # is built from, so `nix shell/run/develop nixpkgs#...` and any project
      # flake using the indirect `inputs.nixpkgs.url = "nixpkgs"` ref resolve to
      # the same tree as the system. The rev is taken from our own nixpkgs input,
      # so it re-syncs automatically on every `nix flake update` of this flake.
      # (Done here rather than via nix-darwin's nix.registry because
      # nix.enable = false, so the nix module is inactive — same reason the
      # token lives here.)
      ".config/nix/registry.json".text = builtins.toJSON {
        version = 2;
        flakes = [
          {
            from = {
              type = "indirect";
              id = "nixpkgs";
            };
            to = {
              type = "github";
              owner = "NixOS";
              repo = "nixpkgs";
              rev = nixpkgs.rev;
            };
          }
        ];
      };

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

      ".claude/settings.json".text =
        let
          npmvet = pkgs.callPackage ./pkgs/npmvet { };
          statusline-command = pkgs.writeShellScript "statusline-command" ''
              # Claude Code status line
              # Left: dir + git | Right: model, effort, context%, sid, time
              export PATH=${
                pkgs.lib.makeBinPath [
                  pkgs.jq
                  pkgs.git
                  pkgs.coreutils
                  pkgs.inetutils
                ]
              }:$PATH

              input=$(cat)

              cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
              model=$(echo "$input" | jq -r '.model.display_name // ""')
              used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
              session_id=$(echo "$input" | jq -r '.session_id // empty')

              # Shorten home directory to ~
              home="$HOME"
              short_cwd="''${cwd/#$home/\~}"

              # Git branch and status
              git_info=""
              if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
                branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
                      || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
                if [ -n "$branch" ]; then
                  dirty=""
                  if ! git -C "$cwd" -c gc.auto=0 diff --quiet 2>/dev/null \
                    || ! git -C "$cwd" -c gc.auto=0 diff --cached --quiet 2>/dev/null; then
                    dirty="*"
                  fi
                  git_info=" \033[33m$branch$dirty\033[0m"
                fi
              fi

              # Effort (try common field names; falls back to output_style.name)
              effort=$(echo "$input" | jq -r '.effort.level // .reasoning_effort // .model.effort // .thinking.effort //
            .output_style.name // empty')
              effort_part=""
              if [ -n "$effort" ]; then
                effort_part=" \033[32m($effort)\033[0m"
              fi

              # Context usage
              ctx_part=""
              if [ -n "$used_pct" ]; then
                printf_pct=$(printf "%.0f" "$used_pct")
                ctx_part=" ctx:$printf_pct%"
              fi

              # Session ID (first 8 chars)
              session_id_part=""
              if [ -n "$session_id" ]; then
                session_id_part=" sid:''${session_id:0:8}"
              fi

              # Time
              time_part=$(date +%H:%M:%S)

              printf "\033[34m%s\033[0m%b  \033[36m%s\033[0m%b%s%s%b  %s" \
                "$short_cwd" \
                "$git_info" \
                "$model" \
                "$effort_part" \
                "$ctx_part" \
                "$session_id_part" \
                "$time_part"
          '';
          npm-security-check = pkgs.writeShellScript "npm-security-check" ''
            # Read the tool input from stdin (Claude Code passes it as JSON)
            INPUT=$(cat)

            # Extract the command being run
            COMMAND=$(echo "$INPUT" | ${pkgs.jq}/bin/jq -r '.command // empty' 2>/dev/null)

            # Check if it's an npm install
            if echo "$COMMAND" | ${pkgs.gnugrep}/bin/grep -qE "npm (install|i |add )"; then
              # Extract package name(s)
              PACKAGES=$(echo "$COMMAND" | ${pkgs.gnugrep}/bin/grep -oE "npm (install|i|add) (.+)" | ${pkgs.gawk}/bin/awk '{$1=$2=""; print $0}' | ${pkgs.findutils}/bin/xargs)

              if [ -n "$PACKAGES" ]; then
                echo "Running npmvet security check on: $PACKAGES" >&2

                # Run npmvet
                RESULT=$(${npmvet}/bin/npmvet $PACKAGES 2>&1)
                EXIT_CODE=$?

                if [ $EXIT_CODE -ne 0 ]; then
                  echo "BLOCKED: npmvet flagged security issues with: $PACKAGES" >&2
                  echo "$RESULT" >&2
                  echo "Installation blocked by security policy. Review npmvet output above before proceeding manually." >&2
                  exit 1
                fi

                echo "npmvet passed for: $PACKAGES" >&2
              fi
            fi

            exit 0
          '';
        in
        builtins.toJSON {
          env = {
            #CLAUDE_CODE_ENABLE_TELEMETRY = "0";
            #CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
            ENABLE_LSP_TOOL = "1";
          };
          statusLine = {
            type = "command";
            command = "bash ${statusline-command}";
          };
          effortLevel = "max";
          voiceEnabled = true;
          skipAutoPermissionPrompt = true;
          permissions = {
            defaultMode = "auto";
          };
          enabledPlugins = {
            "gopls-lsp@claude-plugins-official" = true;
            "omnisharp@claude-code-lsps" = true;
          };
          tui = "fullscreen";
          hooks = {
            PreToolUse = [
              {
                matcher = "Bash";
                hooks = [
                  {
                    type = "command";
                    command = "${npm-security-check}";
                  }
                ];
              }
            ];
            Stop = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "/usr/bin/osascript -e 'display notification \"Claude Code Finished\" sound name \"Glass\"'";
                  }
                ];
              }
            ];
            Notification = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "/usr/bin/osascript -e 'display notification \"Claude Code needs permission\" sound name \"Sosumi\"'";
                  }
                ];
              }
            ];
          };
        };

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

      "Library/Application Support/com.mitchellh.ghostty/config".source = ./share/ghostty.config;

      ".claude/skills/plan-exit-review/SKILL.md".source = ./share/plan-exit-review.md;
      ".copilot/skills/plan-exit-review/SKILL.md".source = ./share/plan-exit-review.md;
      ".claude/skills/plan-ceo-review/SKILL.md".source = "${gstack}/plan-ceo-review/SKILL.md";
      ".copilot/skills/plan-ceo-review/SKILL.md".source = "${gstack}/plan-ceo-review/SKILL.md";
      ".claude/skills/plan-eng-review/SKILL.md".source = "${gstack}/plan-eng-review/SKILL.md";
      ".copilot/skills/plan-eng-review/SKILL.md".source = "${gstack}/plan-eng-review/SKILL.md";
      ".claude/skills/retro/SKILL.md".source = "${gstack}/retro/SKILL.md";
      ".copilot/skills/retro/SKILL.md".source = "${gstack}/retro/SKILL.md";
      ".claude/skills/mach-engineering-retro/SKILL.md".source = ./share/mach-engineering-retro.md;
      ".copilot/skills/mach-engineering-retro/SKILL.md".source = ./share/mach-engineering-retro.md;
      ".claude/skills/mach-linear-ticket/SKILL.md".source = ./share/mach-linear-ticket.md;
      ".copilot/skills/mach-linear-ticket/SKILL.md".source = ./share/mach-linear-ticket.md;
      ".claude/skills/mach-product-ticket/SKILL.md".source = ./share/mach-product-ticket.md;
      ".copilot/skills/mach-product-ticket/SKILL.md".source = ./share/mach-product-ticket.md;
    };

  home.sessionVariables = {
    NH_FLAKE = "/Users/c.lawson/src/github.com/au-phiware/etc-nixos";
  };

  # Write the GitHub token that ~/.config/nix/nix.conf includes, sourced from
  # the gh CLI keychain entry. Kept out of the repo (mode 600). Refreshed on
  # every activation; skipped without noise if gh has no token.
  home.activation.githubAccessToken = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _tokenFile="${config.home.homeDirectory}/.config/nix/access-tokens.conf"
    if _ghToken=$(${pkgs.gh}/bin/gh auth token 2>/dev/null) && [ -n "$_ghToken" ]; then
      run mkdir -p "$(dirname "$_tokenFile")"
      run install -m 600 /dev/null "$_tokenFile"
      printf 'access-tokens = github.com=%s\n' "$_ghToken" > "$_tokenFile"
    else
      warnEcho "gh auth token unavailable; ~/.config/nix/access-tokens.conf not written (Nix GitHub API calls will be unauthenticated)"
    fi
  '';

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
      init = {
        defaultBranch = "main";
      };
      push = {
        default = "current";
      };
      pull = {
        rebase = true;
      };
      merge = {
        conflictStyle = "zdiff3";
      };
      diff = {
        algorithm = "histogram";
      };
      commit = {
        template = "${./share/gitconfig/commit-template}";
        verbose = true;
      };
      rebase = {
        updateRefs = true;
      };
      rerere = {
        enabled = true;
      };
      branch = {
        autosetupmerge = true;
      };
      credential = {
        "https://github.com" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
        "https://gist.github.com" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
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
