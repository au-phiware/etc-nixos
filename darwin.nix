{ pkgs, lib, primaryUser, nixos-npm-ls, ... }: {
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

  nixpkgs.config.allowUnfreePredicate = pkg:
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
          meta = old.meta // { broken = false; };
          doCheck = false;
          doInstallCheck = false;
          checkPhase = "true";
          installCheckPhase = "true";
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

    uv
    nodejs

    #awscli2
    #saml2aws
    ssm-session-manager-plugin
    gh
    #zed-editor
    #oterm
    kitty
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
    claude-code
    (callPackage ./pkgs/copilot { })
    opencode

    #mermaid-cli
    #puppeteer-cli
    #imagemagick
    #inkscape
  ];

  #homebrew.enable = true;
  #homebrew.brews = [ "mermaid-cli" ];

  # Fonts to install into /Library/Fonts/Nix Fonts
  fonts.packages = with pkgs; [
    #corefonts
    #typodermic-free-fonts
    typodermic-public-domain
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
  services.ollama = { enable = true; };

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
