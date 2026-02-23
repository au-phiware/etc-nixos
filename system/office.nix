# Office role configuration
# Printing, document handling, browsers, communication
{ config, lib, pkgs, unstable, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [ "ventoy-1.1.07" ];

  # Printing
  services.printing.enable = true;

  # DNS resolution (for VPN, etc.)
  services.resolved.enable = true;

  # ZFS services
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 9;
      hourly = 24;
      daily = 32;
      weekly = 8;
      monthly = 13;
    };
  };

  # Keyring for credential storage
  services.gnome.gnome-keyring.enable = true;

  # Office packages
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    chromium
    brave

    # PDF tools
    qpdf
    qpdfview

    # Image editing
    gimp

    # Spelling
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science

    # Utilities
    wgetpaste
    cabextract
    ventoy

    # 3D printing / making
    openscad
    openscad-lsp
    orca-slicer

    # Secrets management
    seahorse
    gnome-keyring
    libsecret
  ];
}
