# Gaming role configuration
{ config, lib, pkgs, ... }:

{
  # Steam
  programs.steam.enable = true;

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Minecraft
    prismlauncher
    jdk21_headless
    jdk17_headless

    # Graphics testing
    mesa-demos

    # Veloren launcher
    airshipper
  ];
}
