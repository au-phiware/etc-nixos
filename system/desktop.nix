# Desktop environment configuration
# Niri window manager, display, audio, Stylix theming
{ config, lib, pkgs, inputs, unstable, theme, ... }:

{
  # Niri window manager (use nixpkgs-unstable to avoid flake build issues)
  programs.niri = {
    enable = true;
    package = unstable.niri;
  };

  # Display manager
  services.xserver.enable = true;
  services.displayManager = {
    defaultSession = "niri";
    autoLogin = {
      enable = true;
      user = "corin";
    };
  };

  # Stylix theming
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "dark";
    image = theme.wallpaper;
    base16Scheme = {
      base00 = theme.colors.base03;  # Default background
      base01 = theme.colors.base02;  # Lighter background
      base02 = theme.colors.base01;  # Selection background
      base03 = theme.colors.base00;  # Comments
      base04 = theme.colors.base0;   # Dark foreground
      base05 = theme.colors.base1;   # Default foreground
      base06 = theme.colors.base2;   # Light foreground
      base07 = theme.colors.base3;   # Light background
      base08 = theme.colors.red;     # Variables
      base09 = theme.colors.orange;  # Integers
      base0A = theme.colors.yellow;  # Classes
      base0B = theme.colors.green;   # Strings
      base0C = theme.colors.cyan;    # Support
      base0D = theme.colors.blue;    # Functions
      base0E = theme.colors.violet;  # Keywords
      base0F = theme.colors.magenta; # Deprecated
    };
    fonts = {
      sansSerif = {
        package = pkgs.corefonts;
        name = theme.fonts.sansSerif.name;
      };
      monospace = {
        package = pkgs.powerline-fonts;
        name = theme.fonts.monospace.name;
      };
      sizes = {
        terminal = 10;
        applications = 11;
        desktop = 11;
      };
    };
  };

  # Audio via Pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;  # Auto-power adapter on boot so paired devices reconnect
    settings = {
      General = {
        FastConnectable = true;
        Experimental = true;  # Enables LE background scanning / auto-connect
      };
      Policy.AutoEnable = true;
    };
  };
  services.blueman.enable = true;

  # Thunderbolt
  services.hardware.bolt.enable = true;

  # Dconf for GTK settings
  programs.dconf.enable = true;

  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    wl-clipboard

    # Audio control
    alsa-utils
    pavucontrol

    # Display tools
    brightnessctl
    wdisplays

    # Desktop integration
    xdg-desktop-portal-wlr
    libnotify

    # Screenshot tools
    grim
    slurp

    # Image tools
    imagemagick
    imv
  ];

  # Session variables for Wayland
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DBUS_REMOTE = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
