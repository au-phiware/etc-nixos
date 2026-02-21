# Desktop home-manager configuration
# Niri, foot, fuzzel, eww, mako, kanshi, swaylock-effects
{ config, lib, pkgs, inputs, unstable, theme, ... }:

let
  c = theme.hashColors;

  # Get focused output name from niri
  focusedOutput = ''
    output=$(${unstable.niri}/bin/niri msg --json workspaces \
      | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused) | .output' \
      | head -1)
  '';

  # Screenshot scripts scoped to the focused output
  # Interactive (Print): slurp for region selection on focused output → satty for annotation
  # Full (Ctrl+Print): grim captures focused output directly
  screenshotGui = pkgs.writeShellScriptBin "screenshot-gui.sh" ''
    ${focusedOutput}
    region=$(${pkgs.slurp}/bin/slurp -o "$output") || exit 0
    ${pkgs.grim}/bin/grim -g "$region" - \
      | ${pkgs.satty}/bin/satty --filename - \
          --output-filename "${config.home.homeDirectory}/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
  '';
  screenshotGuiClip = pkgs.writeShellScriptBin "screenshot-gui-clip.sh" ''
    ${focusedOutput}
    region=$(${pkgs.slurp}/bin/slurp -o "$output") || exit 0
    ${pkgs.grim}/bin/grim -g "$region" - \
      | ${pkgs.satty}/bin/satty --filename - --copy-command ${pkgs.wl-clipboard}/bin/wl-copy
  '';
  screenshotFull = pkgs.writeShellScriptBin "screenshot-full.sh" ''
    ${focusedOutput}
    exec ${pkgs.grim}/bin/grim -o "$output" \
      "${config.home.homeDirectory}/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
  '';
  screenshotFullClip = pkgs.writeShellScriptBin "screenshot-full-clip.sh" ''
    ${focusedOutput}
    ${pkgs.grim}/bin/grim -o "$output" - | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  # Lock script using swaylock-effects
  lockScript = pkgs.writeShellScriptBin "lock.sh" ''
    ${pkgs.swaylock-effects}/bin/swaylock \
      --screenshots \
      --clock \
      --indicator \
      --indicator-radius 100 \
      --indicator-thickness 7 \
      --effect-blur 7x5 \
      --effect-vignette 0.5:0.5 \
      --ring-color "${c.green}" \
      --key-hl-color "${c.blue}" \
      --line-color "00000000" \
      --inside-color "${c.base03}88" \
      --separator-color "00000000" \
      --grace 2 \
      --fade-in 0.2
  '';
in
{
  imports = [
    ./core.nix
    ./coding.nix
    ./office.nix
    ./gaming.nix
  ];

  home.packages = with pkgs; [
    # Screen locking
    swaylock-effects
    swayidle
    lockScript

    # Clipboard
    wl-clipboard

    # Display management
    wdisplays
    kanshi

    # Notifications
    mako
    libnotify

    # Terminal
    foot

    # Launcher
    fuzzel

    # Status bar
    eww

    # Screenshots
    grim
    slurp
    satty

    # Wallpaper
    swaybg

    # Screenshot helpers
    screenshotGui
    screenshotGuiClip
    screenshotFull
    screenshotFullClip

    # File manager
    yazi

    # On-screen display for volume/brightness
    swayosd
  ];

  # Niri window manager
  programs.niri = {
    settings = {
      input = {
        keyboard.xkb.layout = "us";
        touchpad = {
          tap = true;
          natural-scroll = true;
          dwt = false;  # Disable while typing
        };
        focus-follows-mouse.enable = true;
      };

      # Minimal gaps for fullscreen focus
      layout = {
        gaps = 0;
        default-column-width.proportion = 1.0;  # Fullscreen by default
        border.enable = false;
        focus-ring = {
          enable = true;
          width = 2;
          active.color = theme.hashColors.green;
          inactive.color = "${theme.hashColors.base01}80";
        };
      };

      prefer-no-csd = true;

      environment.DISPLAY = ":0";

      # Smooth animations
      animations.slowdown = 1.0;

      binds = with config.lib.niri.actions; {
        # Show hotkey overlay
        "Mod+Shift+Slash".action = show-hotkey-overlay;

        # Terminal
        "Mod+Shift+Return".action = spawn "${pkgs.foot}/bin/foot";

        # Close window
        "Mod+Shift+c".action = close-window;

        # Launcher
        "Mod+p".action = spawn "${pkgs.fuzzel}/bin/fuzzel";

        # Maximize column (fills the width of the screen)
        "Mod+Space".action = maximize-column;

        # Fullscreen (hides bar too)
        "Mod+f".action = fullscreen-window;

        # Floating toggle
        "Mod+Shift+Space".action = toggle-window-floating;

        # Lock screen
        "Mod+x".action = spawn "${lockScript}/bin/lock.sh";

        # Screenshots via flameshot (scoped to focused output)
        # Print / Mod+Print       → interactive region, save to file
        # Shift+Print             → interactive region, copy to clipboard
        # Ctrl+Print              → full screen, save to file
        # Ctrl+Shift+Print        → full screen, copy to clipboard
        "Print".action            = spawn "${screenshotGui}/bin/screenshot-gui.sh";
        "Mod+Print".action        = spawn "${screenshotGui}/bin/screenshot-gui.sh";
        "Shift+Print".action      = spawn "${screenshotGuiClip}/bin/screenshot-gui-clip.sh";
        "Mod+Shift+Print".action  = spawn "${screenshotGuiClip}/bin/screenshot-gui-clip.sh";
        "Ctrl+Print".action       = spawn "${screenshotFull}/bin/screenshot-full.sh";
        "Mod+Ctrl+Print".action   = spawn "${screenshotFull}/bin/screenshot-full.sh";
        "Ctrl+Shift+Print".action      = spawn "${screenshotFullClip}/bin/screenshot-full-clip.sh";
        "Mod+Ctrl+Shift+Print".action  = spawn "${screenshotFullClip}/bin/screenshot-full-clip.sh";

        # Column navigation (left/right between columns)
        "Mod+Left".action = focus-column-left;
        "Mod+Right".action = focus-column-right;
        "Mod+h".action = focus-column-left;
        "Mod+l".action = focus-column-right;

        # Window navigation (up/down within a column)
        "Mod+Up".action = focus-window-up;
        "Mod+Down".action = focus-window-down;
        "Mod+k".action = focus-window-up;
        "Mod+j".action = focus-window-down;

        # Move columns within a workspace
        "Mod+Shift+Left".action = move-column-left;
        "Mod+Shift+Right".action = move-column-right;
        "Mod+Shift+h".action = move-column-left;
        "Mod+Shift+l".action = move-column-right;

        # Move windows within a column
        "Mod+Shift+Up".action = move-window-up;
        "Mod+Shift+Down".action = move-window-down;
        "Mod+Shift+k".action = move-window-up;
        "Mod+Shift+j".action = move-window-down;

        # Focus monitor (hjkl + arrows)
        "Mod+Ctrl+h".action = focus-monitor-left;
        "Mod+Ctrl+l".action = focus-monitor-right;
        "Mod+Ctrl+k".action = focus-monitor-up;
        "Mod+Ctrl+j".action = focus-monitor-down;
        "Mod+Ctrl+Left".action = focus-monitor-left;
        "Mod+Ctrl+Right".action = focus-monitor-right;
        "Mod+Ctrl+Up".action = focus-monitor-up;
        "Mod+Ctrl+Down".action = focus-monitor-down;

        # Move column to another monitor (Shift + hjkl + arrows)
        "Mod+Ctrl+Shift+Left".action = move-column-to-monitor-left;
        "Mod+Ctrl+Shift+Right".action = move-column-to-monitor-right;
        "Mod+Ctrl+Shift+Up".action = move-column-to-monitor-up;
        "Mod+Ctrl+Shift+Down".action = move-column-to-monitor-down;
        "Mod+Ctrl+Shift+h".action = move-column-to-monitor-left;
        "Mod+Ctrl+Shift+l".action = move-column-to-monitor-right;
        "Mod+Ctrl+Shift+k".action = move-column-to-monitor-up;
        "Mod+Ctrl+Shift+j".action = move-column-to-monitor-down;

        # Consume/expel: manage windows within columns
        "Mod+BracketLeft".action = consume-window-into-column;
        "Mod+BracketRight".action = expel-window-from-column;

        # Resize columns
        "Mod+Minus".action = set-column-width "-10%";
        "Mod+Equal".action = set-column-width "+10%";
        "Mod+Shift+Minus".action = set-window-height "-10%";
        "Mod+Shift+Equal".action = set-window-height "+10%";

        # Cycle preset widths (1/3, 1/2, 2/3)
        "Mod+r".action = switch-preset-column-width;

        # Workspaces
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+Shift+1".action.move-window-to-workspace = 1;
        "Mod+Shift+2".action.move-window-to-workspace = 2;
        "Mod+Shift+3".action.move-window-to-workspace = 3;
        "Mod+Shift+4".action.move-window-to-workspace = 4;
        "Mod+Shift+5".action.move-window-to-workspace = 5;

        # File manager
        "Mod+e".action = spawn "${pkgs.foot}/bin/foot" "${pkgs.yazi}/bin/yazi";

        # Session
        "Mod+Shift+q".action = quit;
        "Mod+Shift+r".action = spawn "niri" "msg" "action" "reload-config";

        # Media keys (swayosd provides on-screen feedback)
        "XF86AudioMute".action = spawn "${pkgs.swayosd}/bin/swayosd-client" "--output-volume" "mute-toggle";
        "XF86AudioLowerVolume".action = spawn "${pkgs.swayosd}/bin/swayosd-client" "--output-volume" "lower";
        "XF86AudioRaiseVolume".action = spawn "${pkgs.swayosd}/bin/swayosd-client" "--output-volume" "raise";
        "XF86MonBrightnessUp".action = spawn "${pkgs.swayosd}/bin/swayosd-client" "--brightness" "raise";
        "XF86MonBrightnessDown".action = spawn "${pkgs.swayosd}/bin/swayosd-client" "--brightness" "lower";
      };

      spawn-at-startup = [
        { command = [ "${pkgs.xwayland-satellite}/bin/xwayland-satellite" ]; }
        { command = [ "${pkgs.swaybg}/bin/swaybg" "-i" "${theme.wallpaper}" "-m" "fill" ]; }
        { command = [ "${pkgs.swayosd}/bin/swayosd-server" ]; }
        { command = [ "${pkgs.foot}/bin/foot" ]; }
        { command = [ "${pkgs.eww}/bin/eww" "open" "bar" ]; }
        { command = [ "${pkgs.mako}/bin/mako" ]; }
      ];
    };
  };

  # Foot terminal - Stylix handles colors and fonts
  programs.foot = {
    enable = true;
    settings = {
      main.dpi-aware = lib.mkForce "yes";
      cursor = {
        style = "beam";
        blink = "yes";
      };
      mouse.hide-when-typing = "yes";
    };
  };

  # Fuzzel launcher - Stylix handles colors
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.foot}/bin/foot";
        layer = "overlay";
        lines = 8;
        width = 40;
        horizontal-pad = 20;
        vertical-pad = 10;
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };

  # Mako notifications - Stylix handles theming
  services.mako = {
    enable = true;
    settings = {
      border-radius = 6;
      border-size = 4;
      padding = "10";
      margin = "14";
      default-timeout = 5000;
      icon-path = "/run/current-system/sw/share/icons/hicolor:/run/current-system/sw/share/pixmaps";
    };
  };

  # Kanshi display profiles
  # Criteria use full display descriptions (make model serial) for robustness
  services.kanshi = {
    enable = true;
    settings = [
      {
        # Laptop only
        profile.name = "undocked";
        profile.outputs = [
          { criteria = "LG Display 0x046F Unknown"; status = "enable"; mode = "1920x1080@60"; position = "0,0"; }
        ];
      }
      {
        # Both BenQ monitors, no laptop screen
        # [DP-1 1920x1080] [HDMI-A-1 1920x1080]
        profile.name = "dual-external";
        profile.outputs = [
          { criteria = "PNP(BNQ) BenQ GL2460 R7E01381SL0";  status = "enable"; mode = "1920x1080@60"; position = "0,0"; }
          { criteria = "PNP(BNQ) BenQ GL2460 46E01111SL0"; status = "enable"; mode = "1920x1080@60"; position = "1920,0"; }
          { criteria = "LG Display 0x046F Unknown"; status = "disable"; }
        ];
      }
      {
        # All three: two BenQ monitors + laptop screen below right
        # [DP-1 1920x1080] [HDMI-A-1 1920x1080]
        #                  [eDP-1    1920x1080 ]
        profile.name = "docked";
        profile.outputs = [
          { criteria = "PNP(BNQ) BenQ GL2460 R7E01381SL0";  status = "enable"; mode = "1920x1080@60"; position = "0,0"; }
          { criteria = "PNP(BNQ) BenQ GL2460 46E01111SL0"; status = "enable"; mode = "1920x1080@60"; position = "1920,0"; }
          { criteria = "LG Display 0x046F Unknown"; status = "enable"; mode = "1920x1080@60"; position = "1920,1080"; }
        ];
      }
    ];
  };

  # Swayidle for automatic locking
  services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = "${lockScript}/bin/lock.sh"; }
      { event = "lock"; command = "${lockScript}/bin/lock.sh"; }
    ];
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10%";
        resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
      }
      {
        timeout = 600;
        command = "${lockScript}/bin/lock.sh";
      }
      {
        timeout = 1200;
        command = "${unstable.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${unstable.niri}/bin/niri msg action power-on-monitors";
      }
    ];
  };

  # EWW configuration files
  home.file.".config/eww/eww.yuck".text = ''
    ;; Workspace polling
    (defpoll workspaces :interval "200ms" :initial "[]"
      "${unstable.niri}/bin/niri msg --json workspaces | ${pkgs.jq}/bin/jq -c '.'")

    ;; System info
    (defpoll time :interval "1s" :initial "00:00" "date +'%H:%M'")
    (defpoll date :interval "60s" :initial "Mon 01" "date +'%a %d %b'")
    (defpoll battery :interval "10s" :initial "100"
      "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo 100")
    (defpoll volume :interval "1s" :initial "0"
      "${pkgs.pulseaudio}/bin/pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '[0-9]+(?=%)' | head -1")

    ;; Main bar
    (defwindow bar
      :monitor 0
      :windowtype "dock"
      :stacking "fg"
      :reserve (struts :side "bottom" :distance "28px")
      :geometry (geometry :x "0%" :y "0%" :width "100%" :height "28px" :anchor "bottom center")
      :exclusive true
      (bar-content))

    (defwidget bar-content []
      (centerbox :orientation "h" :class "bar"
        (workspaces-widget)
        (clock-widget)
        (system-widget)))

    (defwidget workspaces-widget []
      (box :class "workspaces" :space-evenly false :halign "start"
        (for ws in workspaces
          (button
            :class "workspace ''${ws.is_focused ? "focused" : ""}"
            :onclick "${unstable.niri}/bin/niri msg action focus-workspace ''${ws.idx}"
            "''${ws.idx}"))))

    (defwidget clock-widget []
      (box :class "clock" :space-evenly false :halign "center"
        (label :text time :class "time")
        (label :text " | " :class "separator")
        (label :text date :class "date")))

    (defwidget system-widget []
      (box :class "system" :space-evenly false :halign "end"
        (label :text "Vol ''${volume}%" :class "volume")
        (label :text " | " :class "separator")
        (label :text "Bat ''${battery}%" :class "battery")))
  '';

  home.file.".config/eww/eww.scss".text = ''
    // Solarized Dark
    $base03: ${c.base03};
    $base02: ${c.base02};
    $base01: ${c.base01};
    $base00: ${c.base00};
    $base0: ${c.base0};
    $base1: ${c.base1};
    $base2: ${c.base2};
    $base3: ${c.base3};
    $yellow: ${c.yellow};
    $orange: ${c.orange};
    $red: ${c.red};
    $magenta: ${c.magenta};
    $violet: ${c.violet};
    $blue: ${c.blue};
    $cyan: ${c.cyan};
    $green: ${c.green};

    * {
      all: unset;
      font-family: "${theme.fonts.monospace.name}", monospace;
      font-size: 11px;
    }

    .bar {
      background-color: ${c.bg};
      color: $base1;
      padding: 0 12px;
    }

    .workspaces {
      .workspace {
        padding: 4px 12px;
        margin: 2px 2px;
        background-color: transparent;
        color: $base01;
        border-radius: 4px;

        &:hover {
          background-color: rgba(88, 110, 117, 0.3);
          color: $base1;
        }

        &.focused {
          background-color: $cyan;
          color: $base03;
        }
      }
    }

    .clock {
      .time {
        color: $base1;
        font-weight: bold;
      }
      .date {
        color: $base01;
      }
      .separator {
        color: $base01;
        padding: 0 8px;
      }
    }

    .system {
      .volume, .battery {
        padding: 0 8px;
        color: $base0;
      }
      .separator {
        color: $base01;
      }
    }
  '';

  # XResources for any X11 apps
  xresources.extraConfig = builtins.readFile (
    pkgs.fetchFromGitHub {
      owner = "solarized";
      repo = "xresources";
      rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
      sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
    } + "/Xresources.dark"
  );
}
