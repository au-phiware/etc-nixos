{ config, pkgs, lib, ... }: {
  home.username = "corin.lawson";
  home.homeDirectory = "/Users/corin.lawson";

  # Enable neovim
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    colorschemes.nightfox.enable = true;
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
      copilot-chat.enable = true;
      copilot-lua = {
        enable = true;
        settings.suggestion.enabled = true;
      };
      dap.enable = true;
      dap-ui.enable = true;
      emmet.enable = true;
      friendly-snippets.enable = true;
      fugitive.enable = true;
      git-conflict.enable = true;
      goyo.enable = true;
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          jsonls.enable = true;
          eslint.enable = true;
          marksman.enable = true;
          ts_ls.enable = true;
          nixd.enable = true;
        };
      };
      luasnip = {
        enable = true;
        fromVscode = [
          { }
          { paths = "~/.vscode/snippets"; }
        ];
      };
      markdown-preview.enable = true;
      nix.enable = true;
      none-ls = {
        enable = true;
        sources = {
          formatting = {
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
    '';
    globals = {
      mapleader = " ";
    };
    keymaps = [
      {
        key = "-";
        action = "<cmd>Explore<cr>";
        options.desc = "Open Directory Explorer";
      }
      {
        key = "gD";
        action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
        options.desc = "Goto Declaration";
      }
      {
        key = "gs";
        action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
        options.desc = "Show Signature";
      }
      {
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<cr>";
        options.desc = "Goto Definition";
      }
      {
        key = "gi";
        action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
        options.desc = "Goto Implementation";
      }
      {
        key = "gr";
        action = "<cmd>lua vim.lsp.buf.references()<cr>";
        options.desc = "Goto References";
      }
      {
        key = "gt";
        action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
        options.desc = "Goto Type Definition";
      }
      {
        key = "ga";
        action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
        options.desc = "Trigger Code Action";
      }
      {
        key = "gn";
        action = "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>";
        options.desc = "Goto Next Diagnostic";
      }
      {
        key = "gp";
        action = "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>";
        options.desc = "Goto Previous Diagnostic";
      }
      {
        key = "gu";
        action = "<cmd>lua require('dapui').toggle()<CR>";
        options.desc = "Toggle Dapui";
      }
      {
        key = "gb";
        action = "<cmd>lua require('dap').toggle_breakpoint()<CR>";
        options.desc = "Toggle breakpoint";
      }
    ];
  };

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
      nix-switch = ''pushd /etc/nix-darwin; darwin-rebuild switch --flake .; popd'';
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
  home.file = {
    ".cvsignore".source = ./share/cvsignore;

    "Library/Application Support/oterm/config.json".text = ''
      {
        "mcpServers": {
          "brave-search": {
            "command": "${pkgs.nodejs_22}/bin/npx",
            "args": ["-y", "@modelcontextprotocol/server-brave-search"],
            "env": {
              "BRAVE_API_KEY": "BSAWajempQpDBcKfQ_yOqoH-Ob1Bq36"
            }
          },
          "git": {
            "command": "${pkgs.uv}/bin/uvx",
            "args": [
              "mcp-server-git",
              "--repository", "${config.home.homeDirectory}/src/github.com/CBA-General/paas",
              "--repository", "${config.home.homeDirectory}/src/github.com/CBA-General/paas-payment-initiation"
            ]
          },
          "filesystem": {
            "command": "${pkgs.nodejs_22}/bin/npx",
            "args": ["-y", "@modelcontextprotocol/server-filesystem", "${config.home.homeDirectory}"]
          }
        },
        "theme": "textual-dark",
        "splash-screen": false
      }
    '';

    ".claude/settings.json".text = builtins.toJSON
      {
        permissions = {
          allow = [
            "Bash(pnpm lint:fix)"
          ];
        };
        env = {
          CLAUDE_CODE_ENABLE_TELEMETRY = "0";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          CLAUDE_CODE_SKIP_BEDROCK_AUTH = "0";
          ANTHROPIC_BASE_URL = "https://api.studio.genai.cba";
          ANTHROPIC_MODEL = "aipe-bedrock-claude-4-sonnet";
          ANTHROPIC_SMALL_FAST_MODEL = "aipe-bedrock-claude-3-7-sonnet";
          DISABLE_PROMPT_CACHING = "1";
          CLAUDE_CODE_MAX_OUTPUT_TOKENS = 8192;
          MAX_THINKING_TOKENS = 2048;
          CLAUDE_CODE_API_KEY_HELPER_TTL_MS = 3600000;
        };
        hooks = {
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = ''${pkgs.terminal-notifier}/bin/terminal-notifier -message "Claude Code Finished" -sound default'';
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
                  command = ''${pkgs.terminal-notifier}/bin/terminal-notifier -message "Claude Code needs permission" -sound Basso'';
                }
              ];
            }
          ];
        };
        apiKeyHelper = pkgs.writeShellScript "claude-apiKeyHelper" ''
          declare mdat
          while read -r line; do
            case "$line" in
              '"mdat"<timedate>='*' "'??????????????'Z'*)
                mdat="''${line%Z*}"
                mdat="''${mdat#*\"}"
                ;;
            esac
          done < <(security find-generic-password -a "$USER" -s openai-api-key -g 2>&1)
          if [[ "$mdat" < "$(date --date '7 days ago' +'"%Y%m%d%H%M%S')" ]]; then
            echo "Error: openai-api-key has expired, please go to https://studio.genai.cba to generate a new key then run:"
            echo "    security add-generic-password -a $USER -s openai-api-key -U -w"
            exit 1
          fi

          security find-generic-password -a "$USER" -s openai-api-key -w
        '';
      };

      ".claude/agents".source = let
        wshobsonAgents = pkgs.fetchFromGitHub {
          owner = "wshobson";
          repo = "agents";
          rev = "main";
          sha256 = "sha256-tOI2GvO4eUREC3YtBlzbIxwySwzGwsK4tGbOX5Q67NM=";
          # Filter: include *.md only, except README.md
          postFetch = ''
            cd $out
            ${pkgs.findutils}/bin/find . -type f -not -name '*.md' -delete
            rm -f README.md
          '';
        };
      in
        wshobsonAgents;
        #pkgs.runCommand "claude-agents" {} ''
        #  ln -s ${wshobsonAgents}/* $out/
        #'';

      ".claude/commands".source = let
        wshobsonCommands = pkgs.fetchFromGitHub {
          owner = "wshobson";
          repo = "commands";
          rev = "main";
          sha256 = "sha256-HammY2FLNa4xCRlD2XJUgXj8lkLijQ47Prm4lA4iaZU=";
          # Filter: include *.md only, except README.md
          postFetch = ''
            cd $out
            ${pkgs.findutils}/bin/find . -type f -not -name '*.md' -delete
            rm -f README.md
          '';
        };
      in
        wshobsonCommands;
        #pkgs.runCommand "claude-commands" {} ''
        #  ln -s ${wshobsonCommands}/* $out/
        #'';
  };

  home.sessionVariables = {
    NH_FLAKE = "/etc/nix-darwin";
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "Corin Lawson";
    userEmail = "Corin.Lawson@cba.com.au";
    aliases = {
      amend = "commit --amend --signoff";
      wip = "commit --no-verify -m WIP";
      sign = "commit --signoff --gpg-sign";
      fixup = "commit --fixup";
      autosquash = "rebase --interactive --autosquash";
      force-push = "push --force";
      log-all = "log --all --graph --decorate --oneline";
    };
    extraConfig = {
      core = {
        excludesfile = "${./share/cvsignore}";
        #hooksPath = "${config.home.homeDirectory}/.local/share/gitconfig/hooks";
      };
      init = {defaultBranch = "main";};
      push = {default = "current";};
      pull = {rebase = true;};
      merge = {conflictStyle = "zdiff3";};
      diff = {algorithm = "histogram";};
      commit = {
        template = "${./share/gitconfig/commit-template}";
        verbose = true;
      };
      rebase = {updateRefs = true;};
      rerere = {enabled = true;};
      branch = {autosetupmerge = true;};
      credential = {
        "https://github.com" = {
          helper = ["" "!${pkgs.gh}/bin/gh auth git-credential"];
        };
        "https://gist.github.com" = {
          helper = ["" "!${pkgs.gh}/bin/gh auth git-credential"];
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
    delta = {
      enable = true;
      #options.theme = "Solarized (dark)";
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Corin Lawson";
        email = "Corin.Lawson@cba.com.au";
      };
      template-aliases = {
        default_commit_description = ''
          "JJ: If applied, this commit will...

          JJ: Why is this change needed?
          Prior to this change, 

          JJ: How does it address the issue?
          This change

          JJ: Provide links to any relevant tickets, articles or other resources
          "
        '';
      };
      ui = {
        default-command = ["status"];
        bookmark-list-sort-keys = ["committer-date-"];
        movement.edit = true;
        pager = ":builtin";
        streampager.interface = "quit-if-one-page";
      };
    };
  };

  home.file."bin/check-for-paas-changes" = {
    text = ''
      #!${pkgs.bash}/bin/bash

      temp_dir=$(${pkgs.coreutils}/bin/mktemp -d)
      commitish=''${1-fbcb9a1d481ad8de4f7f7461bc281b6c44e89b5b}
      file_list=''${2-${./paas-diff-files}}

      if [[ ! -d "$temp_dir" ]]; then
          echo "Failed to create temporary directory" >&2
          exit 1
      fi

      ${pkgs.git}/bin/git clone https://github.com/CBA-General/paas "$temp_dir";
      ${pkgs.git}/bin/git -C "$temp_dir" --no-pager diff --exit-code "$commitish..origin/main" $(${pkgs.coreutils}/bin/cat "$file_list")

      # Clean up the temporary directory
      trap '${pkgs.coreutils}/bin/rm -rf "$temp_dir"' EXIT
    '';
    executable = true;
  };

  launchd = {
    enable = true;
    agents.daily-check-for-paas-changes = {
      enable = true;
      config = {
        ProgramArguments = [
          "${config.home.file."bin/check-for-paas-changes".source}"
        ];
        StartCalendarInterval = [
          {
            Hour = 10;
            Minute = 0;
          }
        ];
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/daily-check-for-paas-changes.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/daily-check-for-paas-changes.err";
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
  home.stateVersion = "24.11"; # Please read the comment before changing.
}
