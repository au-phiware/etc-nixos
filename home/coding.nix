# Coding home-manager configuration
# Vim, neovim (nixvim), editors, development tools
{ pkgs, ... }:

{
  # Neovim via nixvim
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
        gopls = {
          enable = true;
          settings.gopls = {
            staticcheck = true;
            vulncheck = "Imports";
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
        jqls.enable = true;
        jsonls.enable = true;
        marksman.enable = true;
        nixd.enable = true;
        sqls.enable = true;
        typos_lsp.enable = true;
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
      dap.enable = true;
      dap-ui.enable = true;
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
      repeat.enable = true;
      sleuth.enable = true;
      startify.enable = true;
      toggleterm.enable = true;
    };
    extraConfigLua = ''
      vim.o.grepprg = "${pkgs.ripgrep}/bin/rg --vimgrep --smart-case"
      vim.o.grepformat = "%f:%l:%c:%m"
    '';
    globals.mapleader = " ";
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

  # Vim configuration (disabled: superseded by nixvim above)
  programs.vim = {
    enable = false;
    plugins = with pkgs.vimPlugins; [
      vim-surround
      vim-repeat
      vim-fugitive
      vim-sleuth
      vim-speeddating
      vim-commentary
      vim-vinegar
      emmet-vim
      vim-colors-solarized
      vim-airline
      vim-airline-themes
      vim-dispatch
      rainbow_parentheses
      vim-clojure-static
      vim-clojure-highlight
      vim-sexp
      vim-sexp-mappings-for-regular-people
      vim-go
      rust-vim
      tagbar
      vim-easytags
      syntastic
      webapi-vim
      goyo-vim
    ];
    settings = {
      background = "dark";
      directory = [ "$HOME/.vim/swapfiles" ];
      expandtab = true;
    };
    extraConfig = ''
      let mapleader=" "
      set termencoding=utf-8 encoding=utf-8
      filetype plugin indent on
      syntax enable
      colorscheme solarized
      let g:airline_theme='solarized'
      let g:airline_solarized_bg='dark'
      let g:airline_powerline_fonts = 1
      set t_Co=16
      nmap <F8> :TagbarToggle<CR>

      " Syntastic
      set statusline+=%#warningmsg#
      set statusline+=%{SyntasticStatuslineFlag()}
      set statusline+=%*
      let g:syntastic_always_populate_loc_list = 1
      let g:syntastic_auto_loc_list = 1
      let g:syntastic_check_on_open = 1
      let g:syntastic_check_on_wq = 0

      " SpiffyFoldtext
      if has('multi_byte')
        let g:SpiffyFoldtext_format = "%c{ }  %<%f{ }╡ %4n lines ╞═%l{╤═}"
      else
        let g:SpiffyFoldtext_format = "%c{ }  %<%f{ }| %4n lines |=%l{/=}"
      endif
      highlight Folded term=NONE cterm=NONE ctermfg=12 ctermbg=0 guifg=Cyan guibg=DarkGrey

      " Rust
      let g:rustfmt_autosave = 1
      let g:rust_clip_command = '${pkgs.wl-clipboard}/bin/wl-copy'
      au FileType rust set foldmethod=syntax

      " Emmet
      let g:user_emmet_expandabbr_key='<Tab>'
      imap <expr> <tab> emmet#expandAbbrIntelligent("\<tab>")

      " Clojure
      au FileType clojure RainbowParenthesesToggle
      au Syntax clojure RainbowParenthesesLoadRound
      au Syntax clojure RainbowParenthesesLoadSquare
      au Syntax clojure RainbowParenthesesLoadBraces

      " Text width
      set colorcolumn=+1

      " Silence markdownlint warnings about GHF markdown
      let g:syntastic_quiet_messages = { 'regex': ["No link definition for link ID '[ x]'"] }
    '';
  };

  # Tmux
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "vi";
    escapeTime = 10;
    historyLimit = 50000;
  };
}
