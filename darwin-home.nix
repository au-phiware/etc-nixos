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
        };
      };
      blink-cmp.enable = true;
      blink-cmp-copilot.enable = true;
      blink-cmp.settings = {
        signature.enabled = true;
        keymap.preset = "super-tab";
        sources = {
          default = [
            #"copilot"
            "lsp"
            "buffer"
            "path"
            "snippets"
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
        settings.suggestion.enabled = false;
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

    # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    # EDITOR = "vim";
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "Corin Lawson";
    aliases = {
      amend = "commit --amend --signoff";
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

  home.file."bin/check-for-paas-changes" = {
    text = ''
      #!${pkgs.bash}/bin/bash

      temp_dir=$(${pkgs.coreutils}/bin/mktemp -d)
      commitish=''${1-b58657f900da01d821d559c2f9f77d4e9096ff81}
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
