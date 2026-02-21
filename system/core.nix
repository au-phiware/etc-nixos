# Core system configuration
# Base settings shared across all hosts: locale, users, nix, security
{ config, lib, pkgs, theme, ... }:

{
  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Timezone and locale
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.supportedLocales = [ "en_AU.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Default shell
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Primary user
  users.users.corin = {
    isNormalUser = true;
    uid = 1000;
    group = "corin";
    extraGroups = [
      "audio"
      "cdrom"
      "networkmanager"
      "plugdev"
      "systemd-journal"
      "usb"
      "video"
      "wheel"
    ];
  };
  users.groups.corin.gid = 1000;

  # Security
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "${pkgs.util-linux}/bin/dmesg";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  security.pam.loginLimits = [
    {
      domain = "corin";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "corin";
      type = "hard";
      item = "nofile";
      value = "65536";
    }
  ];

  security.polkit.enable = true;

  # Essential services
  services.sshd.enable = true;
  services.fwupd.enable = true;

  # GnuPG
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Environment
  environment.variables = {
    EDITOR = "vim";
    TMPDIR = "/tmp";
    XDG_PICTURES_DIR = "$HOME/Pictures";
  };

  # Core system packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    coreutils
    binutils
    pciutils
    usbutils
    moreutils
    util-linux
    file
    tree
    lsof
    htop
    tmux

    # Compression
    zip
    unzip
    zstd

    # Network tools
    wget
    curl
    bind  # dig, nslookup
    inetutils

    # Text/data processing
    jq
    yq

    # Version control
    git
    delta

    # Security
    gnupg
    openssl
  ];

  # Fonts
  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts
      terminus_font
      powerline-fonts
      google-fonts
      nerd-fonts.jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ theme.fonts.sansSerif.name ];
      monospace = [ theme.fonts.monospace.name ];
    };
  };
}
