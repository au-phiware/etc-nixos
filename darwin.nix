{ pkgs, lib, ... }:
let
  proxy = "http://localhost:3128";
  noproxy = "localhost,.localhost,127.0.0.1/8,192.168.0.0/16,.cba,.github.com,.aws.amazon.com,.amazonaws.com,.awsapps.com,.commbank.io,.atlassian.net,api.atlassian.com";
  proxyVariables = {
    HTTP_PROXY = proxy;
    HTTPS_PROXY = proxy;
    ALL_PROXY = proxy;
    http_proxy = proxy;
    https_proxy = proxy;
    all_proxy = proxy;
    no_proxy = noproxy;
    NO_PROXY = noproxy;
  };
in rec {
  imports = [
    ./ollama.nix
  ];

  system.primaryUser = "corin.lawson";

  users.users."${system.primaryUser}" = {
    name = "${system.primaryUser}";
    home = "/Users/${system.primaryUser}";
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
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
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    coreutils
    binutils
    moreutils
    ascii
    file
    htop
    wget
    tree
    jq
    yq
    hexedit
    openssl
    watchexec
    brotli
    xz
    ripgrep
    nh
    nix-output-monitor

    nodejs_22
    corepack_22
    typescript
    typescript-language-server
    uv

    awscli2
    saml2aws
    gh
    jujutsu
    zed-editor
    oterm
    #ghostty
    presenterm
    github-mcp-server
    (pkgs.writeShellScriptBin "claude" (let
      claude-code = pkgs.claude-code;
    in ''
      unset HTTPS_PROXY HTTP_PROXY ALL_PROXY https_proxy http_proxy all_proxy
      GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -a "$USER" -s github-pat -w)"
      export GITHUB_PERSONAL_ACCESS_TOKEN
      exec ${claude-code}/bin/claude "$@"
    ''))
    #python313Packages.huggingface-hub
    (pkgs.writeShellScriptBin "codex" (let
      codex = pkgs.codex;
      #codex = callPackage ./pkgs/codex.nix {};
    in ''
      CLAUDE_CODE_MAX_OUTPUT_TOKENS = 8192;
      MAX_THINKING_TOKENS = 2048;
      export OPENAI_BASE_URL="https://api.studio.genai.cba"
      mdat=($(security find-generic-password -a "$USER" -s openai-api-key -g 2>&1| ${pkgs.gnugrep}/bin/grep '"mdat"'))
      if [[ "''${mdat[1]%%Z*}" < "$(${pkgs.coreutils}/bin/date --date '7 days ago' +'"%Y%m%d%H%M%S')" ]]; then
        echo "Error: openai-api-key has expired, please go to https://studio.genai.cba to generate a new key then run:"
        echo "    security add-generic-password -a "$USER" -s openai-api-key -U -w"
        exit 1
      fi
      export OPENAI_API_KEY="$(security find-generic-password -a "$USER" -s openai-api-key -w)"
      : ''${OPENAI_DEFAULT_MODEL:="aipe-bedrock-claude-4-sonnet"}
      export OPENAI_DEFAULT_MODEL
      exec ${codex}/bin/codex "$@"
    ''))

    (callPackage ./pkgs/cbacert.nix {})
  ];

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
    noto-fonts-emoji
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  programs.zsh.enable = true;

  # Enable nix-index and its command-not-found helper.
  programs.nix-index.enable = true;

  # Unlock sudo commands with Touch ID.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Enable AeroSpace (i3-like) tiling window manager.
  #services.aerospace.enable = true;

  # Enable direnv and lorri
  services.lorri.enable = true;
  programs.direnv.enable = true;

  # Enable ollama
  services.ollama = {
    enable = true;
    environmentVariables = proxyVariables;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
