# Solarized Dark theme and font configuration
# This file is imported by flake.nix and passed to modules via specialArgs
{
  # Solarized Dark palette (without # prefix for flexibility)
  colors = {
    bg      = "001619";  # Custom darker background
    base03  = "002b36";
    base02  = "073642";
    base01  = "586e75";
    base00  = "657b83";
    base0   = "839496";
    base1   = "93a1a1";
    base2   = "eee8d5";
    base3   = "fdf6e3";
    yellow  = "b58900";
    orange  = "cb4b16";
    red     = "dc322f";
    magenta = "d33682";
    violet  = "6c71c4";
    blue    = "268bd2";
    cyan    = "2aa198";
    green   = "859900";
  };

  # With # prefix for use in configs that expect it
  hashColors = {
    bg      = "#001619";
    base03  = "#002b36";
    base02  = "#073642";
    base01  = "#586e75";
    base00  = "#657b83";
    base0   = "#839496";
    base1   = "#93a1a1";
    base2   = "#eee8d5";
    base3   = "#fdf6e3";
    yellow  = "#b58900";
    orange  = "#cb4b16";
    red     = "#dc322f";
    magenta = "#d33682";
    violet  = "#6c71c4";
    blue    = "#268bd2";
    cyan    = "#2aa198";
    green   = "#859900";
  };

  fonts = {
    monospace = {
      name = "Cousine for Powerline";
      package = "powerline-fonts";
    };
    sansSerif = {
      name = "Verdana";
      package = "corefonts";
    };
    # Alternative monospace fonts to try
    alternativeMonospace = {
      name = "JetBrainsMono Nerd Font";
      package = "nerd-fonts.jetbrains-mono";
    };
  };

  # Wallpaper path (relative to flake root)
  wallpaper = ./share/background.png;
}
