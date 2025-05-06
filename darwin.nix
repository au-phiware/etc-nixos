{ pkgs, ... }:
let
  proxy = "http://localhost:3128";
  proxyVariables = {
    HTTP_PROXY = proxy;
    HTTPS_PROXY = proxy;
    ALL_PROXY = proxy;
    http_proxy = proxy;
    https_proxy = proxy;
    all_proxy = proxy;
  };
in {
  imports = [
    ./ollama.nix
  ];

  users.users."corin.lawson" = {
    name = "corin.lawson";
    home = "/Users/corin.lawson";
  };

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

    nodejs_22
    corepack_22
    typescript
    typescript-language-server
    uv

    awscli2
    saml2aws
    gh
    zed-editor
    oterm
    #ghostty

    (callPackage ./pkgs/cbacert.nix {})
  ];

  # Fonts to install into /Library/Fonts/Nix Fonts
  fonts.packages = with pkgs; [
    #corefonts
    #typodermic-free-fonts
    typodermic-public-domain
    open-sans
    google-fonts
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
