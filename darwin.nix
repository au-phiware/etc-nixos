{
  pkgs,
  lib,
  primaryUser,
  nixos-npm-ls,
  ...
}:
{
  imports = [
    ./ollama.nix
    #./litellm.nix
  ];

  system = {
    inherit primaryUser;

    startup.chime = false;

    defaults = {
      # enable tap to click and drag
      trackpad = {
        Clicking = true;
        Dragging = true;
      };

      finder.ShowPathbar = true;
      NSGlobalDomain = {
        #AppleIconAppearanceTheme = "TintedDark";
      };

      # settings for PaperWM.spoon
      dock.mru-spaces = false;
      spaces.spans-displays = false;
    };
  };

  users.users."${primaryUser}" = {
    name = "${primaryUser}";
    home = "/Users/${primaryUser}";
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "github-copilot-cli"
      "1password"
      "1password-cli"
    ];

  nixpkgs.overlays = [
    (self: super: {
      python313Packages = super.python313Packages // {
        textual = super.python313Packages.textual.overrideAttrs (old: {
          meta = old.meta // {
            broken = false;
          };
          doCheck = false;
          doInstallCheck = false;
          checkPhase = "true";
          installCheckPhase = "true";
        });
      };
    })
    (self: super: {
      vimPlugins = super.vimPlugins // {
        copilot-lua = super.vimPlugins.copilot-lua.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            chmod -R +r copilot/js/ 2>/dev/null || true
          '';
        });
      };
    })
    nixos-npm-ls.overlays.default
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    coreutils
    binutils
    ascii
    file
    htop
    wget
    tree
    jq
    yq-go
    hexedit
    openssl
    watchexec
    brotli
    xz
    ripgrep
    nh
    nix-output-monitor
    unixtools.watch

    uv
    nodejs

    #awscli2
    #saml2aws
    ssm-session-manager-plugin
    gh
    git-filter-repo
    #zed-editor
    #oterm
    #ghostty
    #lens-desktop
    presenterm
    vpn-slice
    openvpn
    kubectl
    _1password-cli
    _1password-gui
    dotnet-sdk

    opencode
    #github-mcp-server
    #(pkgs.writeShellScriptBin "claude" (let
    #  claude-code = pkgs.claude-code;
    #in ''
    #  GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -a "$USER" -s github-pat -w)"
    #  export GITHUB_PERSONAL_ACCESS_TOKEN
    #  exec ${claude-code}/bin/claude "$@"
    #''))
    #python313Packages.huggingface-hub
    #codex
    (callPackage ./pkgs/claude-code { })
    (callPackage ./pkgs/copilot { })
    (callPackage ./pkgs/npmvet { })
    opencode

    # cmux.app is a UI app, installed by hand from the DMG (see
    # ./pkgs/cmux for an unused Nix packaging of it). It ships a CLI
    # inside the bundle, so shim just that one binary onto PATH — the
    # bundle's Resources/bin also holds `open`, `ghostty` and `grok`,
    # which must not shadow the system/nixpkgs ones.
    (writeShellScriptBin "cmux" ''
      cli=/Applications/cmux.app/Contents/Resources/bin/cmux
      if [ ! -x "$cli" ]; then
        echo "cmux: $cli not found; install cmux.app from https://github.com/manaflow-ai/cmux/releases" >&2
        exit 127
      fi
      exec "$cli" "$@"
    '')

    #mermaid-cli
    #puppeteer-cli
    imagemagick
    #inkscape
  ];

  #homebrew.enable = true;
  #homebrew.brews = [ "mermaid-cli" ];

  # Fonts to install into /Library/Fonts/Nix Fonts
  fonts.packages = with pkgs; [
    #corefonts
    #typodermic-free-fonts
    #typodermic-public-domain
    open-sans
    #google-fonts
    open-fonts
    terminus_font
    powerline-fonts
    #nerd-fonts
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;

  # Weekly garbage collection. Can't use nix-darwin's `nix.gc` because
  # `nix.enable = false` leaves the whole nix module inactive (same reason the
  # nix.conf and registry live in home-manager). Determinate ships its own GC,
  # but it's disk-pressure-triggered (`nix store gc --max ...`) and never prunes
  # profile generations, so it thrashes for hours once the disk is already full
  # instead of keeping ahead of it.
  #
  # Runs as root so it covers the system profile's generations, not just this
  # user's. `nix-collect-garbage --delete-older-than` prunes old generations of
  # every profile it can see and then collects what that releases, so it does
  # both jobs in one pass. Uses Determinate's nix by absolute path rather than
  # pkgs.nix, to avoid running a second, different nix against the same store.
  launchd.daemons.nix-gc = {
    script = ''
      exec /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 14d
    '';
    serviceConfig = {
      RunAtLoad = false;
      # Sundays at 03:00. Missed runs (machine asleep) fire on next wake.
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 3;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
      LowPriorityIO = true;
      Nice = 10;
    };
  };

  # Enable alternative shell support in nix-darwin.
  programs.zsh.enable = true;

  # Enable nix-index and its command-not-found helper.
  programs.nix-index.enable = true;

  # Unlock sudo commands with Touch ID.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Enable AeroSpace (i3-like) tiling window manager.
  #services.aerospace.enable = true;

  #services.openvpn.servers = {
  #  split = { config = ./share/openvpn/cvpn-endpoint-0e542def271e55c72.ovpn; };
  #};

  # Enable direnv and lorri (but lorri doesn't support determinant nix)
  #services.lorri.enable = true;
  programs.direnv.enable = true;

  # Enable ollama
  services.ollama = {
    enable = true;
  };

  ## Enable litellm with GitHub Copilot proxy
  #services.litellm = {
  #  enable = true;
  #  settings = {
  #    general_settings = {
  #      master_key = "sk-dummy";
  #    };
  #    litellm_settings = {
  #      drop_params = true;
  #    };
  #    model_list = [
  #      {
  #        model_name = "gpt-5";
  #        litellm_params = {
  #          model = "github_copilot/gpt-5";
  #          extra_headers = {
  #            editor-version = "vscode/1.85.1";
  #            editor-plugin-version = "copilot/1.155.0";
  #            Copilot-Integration-Id = "vscode-chat";
  #            user-agent = "GithubCopilot/1.155.0";
  #          };
  #        };
  #      }
  #    ];
  #  };
  #};

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
