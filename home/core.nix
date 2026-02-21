# Core home-manager configuration
# Shell, git, direnv, ssh
{ config, lib, pkgs, theme, ... }:

{
  home.stateVersion = "18.09";

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    history.extended = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "vi-mode"
        "z"
        "git"
        "sudo"
        "per-directory-history"
      ];
    };
    shellAliases = {
      nix-shell = ''nix-shell --command "$SHELL"'';
    };
    localVariables = rec {
      PATH = "$PATH:$HOME/.cargo/bin";
      LOCALE_ARCHIVE = "$HOME/.nix-profile/lib/locale/locale-archive";
      GOPRIVATE = "github.com/au-phiware";
      GONOSUMDB = GOPRIVATE;
    };
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Enable Powerlevel10k instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      ''
        [[ "$TERM" == "linux" ]] && setfont "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz"
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${../share/p10k.zsh}
      ''
    ];
  };

  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Git configuration
  programs.git = {
    enable = true;
    userEmail = "corin@phiware.com.au";
    userName = "Corin Lawson";
    aliases = {
      amend = "commit --amend --signoff";
      sign = "commit --signoff --gpg-sign";
      fixup = "commit --fixup";
      force-push = "push --force";
      log-all = "log --all --graph --decorate --oneline";
    };
    ignores = [
      "*~"
      "*.sw*"
      "/.envrc"
      "/.direnv/"
      "/result"
      "/result-bin"
      "/flake.nix"
      "/flake.lock"
    ];
    extraConfig = {
      core.excludesfile = "~/.cvsignore";
      init.defaultBranch = "main";
      push.default = "simple";
      pull.rebase = true;
      commit = {
        template = "${../share/git-commit-template}";
        verbose = true;
      };
      rebase.interactive = true;
      branch.autosetupmerge = true;
      url = {
        "git@github.com:au-phiware/" = {
          insteadOf = "https://github.com/au-phiware/";
        };
      };
    };
    delta = {
      enable = true;
      options = {
        syntax-theme = "Solarized (dark)";
      };
    };
  };

  # SSH configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
      };
    };
  };

  # Gnome keyring
  services.gnome-keyring.enable = true;
}
