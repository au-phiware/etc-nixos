# Gaming role configuration
{ config, lib, pkgs, unstable, ... }:

{
  # Steam
  programs.steam.enable = true;

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Minecraft
    prismlauncher
    jdk25_headless
    jdk21_headless
    jdk17_headless

    # Graphics testing
    mesa-demos

    # Veloren launcher
    unstable.airshipper
  ];
}
