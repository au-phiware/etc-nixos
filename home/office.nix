# Office home-manager configuration
# Browser settings, document tools
{ config, lib, pkgs, theme, ... }:

{
  # Firefox settings are mostly managed by Stylix
  # Add any manual overrides here if needed

  # Alacritty as backup terminal - Stylix handles colors
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        dynamic_title = true;
        dimensions = { columns = 80; lines = 24; };
        padding = { x = 2; y = 2; };
        dynamic_padding = false;
        decorations = "none";
        startup_mode = "Maximized";
        decorations_theme_variant = "dark";
      };
      scrolling.history = 10000;
      bell.animation = "EaseOut";
    };
  };
}
