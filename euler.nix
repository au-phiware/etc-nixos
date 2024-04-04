# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, lib, pkgs, stable, unstable, ... }:
let
  # nix-channel --add https://nixos.org/channels/nixos-unstable unstable
  font = {
    #monospace = "Cousine Nerd Font";
    monospace = "MonaspaceNeon";
    sansSerif = "Verdana";
  };
  theme = {
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
  python-with-pkgs = with pkgs; python310.withPackages (pypkgs: with pypkgs; [
    flake8
    msgpack
    powerline
    pynvim
    pylint
  ]);
in
rec {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.font = "${pkgs.powerline-fonts}/share/fonts/truetype/Cousine for Powerline.ttf";
  boot.loader.grub.backgroundColor = "${theme.base03}";
  boot.initrd.kernelModules = [ "i915" ];
  #boot.kernelPackages = unstable.linuxPackages_5_10;
  #boot.kernelPackages = pkgs.linuxPackages_5_9;
  #boot.extraModulePackages = with config.boot.kernelPackages; [ akvcam ];
  boot.kernelParams = [
    "snd-intel-dspcfg.dsp_driver=1" # "snd_hda_intel.dmic_detect=0" # Enable sound
    "net.ifnames=0" # Allow wifi interface names longer than 15 chars
    #"intel_iommu=on" # Allow graphics passthru to VMs
    "i915.enable_fbc=1"
    "i915.enable_psr=2"
    #"hugepages=4096" # Good IF you need it
    "vconsole.keymap=us"
    #"vconsole.font=ter-powerline-v24n"
    # Solarized (dark) colours at boot
    "vt.default_red=0x07,0xdc,0x85,0xb5,0x26,0xd3,0x2a,0xee,0x00,0xcb,0x58,0x65,0x83,0x6c,0x93,0xfd"
    "vt.default_grn=0x36,0x32,0x99,0x89,0x8b,0x36,0xa1,0xe8,0x2b,0x4b,0x6e,0x7b,0x94,0x71,0xa1,0xf6"
    "vt.default_blu=0x42,0x2f,0x00,0x00,0xd2,0x82,0x98,0xd5,0x36,0x16,0x75,0x83,0x96,0xc4,0xa1,0xe3"
  ];
  boot.extraModprobeConfig =
    ''
      options kvm ignore_msrs=1
      options kvm-intel nested=1
      options kvm-intel ept=1
      options kvm-intel enable_shadow_vmcs=1
      options kvm-intel enable_apicv=1
    '';
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.blacklistedKernelModules = [
    "snd-soc-dmic"
  ];

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  networking.hostId = "ca900f67";
  networking.hostName = "euler";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager = {
    enable = true;
    # insertNameservers = [ "172.27.0.2" ];
  };
  networking.extraHosts =
    ''
      192.168.122.21 vmware65
      172.17.0.1 euler.docker
      127.0.0.1 euler
    '';

  #powerManagement.cpuFreqGovernor = "performance";
  powerManagement.cpuFreqGovernor = "powersave";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  #networking.dhcpcd.wait = "background";
  #networking.interfaces.wlp0s20f3.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.supportedLocales = [ "en_AU.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  console = {
    # font = "Lat2-Terminus16";
    font = "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz";
    #font = "ter-powerline-v24n";
    keyMap = "us";
  };

  # Enable a Desktop Environment.
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
  };
  services.xserver.enable = true;
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "corin";
  };
  services.xserver.displayManager.lightdm = {
    background = "${./share/background.png}";
    greeters.mini = {
      enable = true;
      user = "corin";
      extraConfig = ''
        [greeter]
        show-password-label = false
        password-label-text = Password:
        show-input-cursor = false

        [greeter-theme]
        font = "${font.sansSerif}"
        font-size = 1em
        text-color = "#080800"
        error-color = "${theme.red}"
        background-color = "${theme.base03}"
        background = "${./share/background.png}"
        window-color = "${theme.base03}"
        border-color = "${theme.base03}"
        border-width = 0px
        layout-space = 1
        password-color = "${theme.base03}"
        password-background-color = "${theme.base3}"
      '';
    };
  };
  nixpkgs.overlays = [
    (self: super: {
      wl-clipboard-x11 = super.stdenv.mkDerivation rec {
        pname = "wl-clipboard-x11";
        version = "5";

        src = super.fetchFromGitHub {
          owner = "brunelli";
          repo = "wl-clipboard-x11";
          rev = "v${version}";
          sha256 = "1y7jv7rps0sdzmm859wn2l8q4pg2x35smcrm7mbfxn5vrga0bslb";
        };

        dontBuild = true;
        dontConfigure = true;
        propagatedBuildInputs = [ super.wl-clipboard ];
        makeFlags = [ "PREFIX=$(out)" ];
      };

      xsel = self.wl-clipboard-x11;
      xclip = self.wl-clipboard-x11;
    })
  ];

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.fwupd.enable = true;

  # Enable sound.
  sound.enable = false;
  #hardware.pulseaudio.enable = true;
  #hardware.pulseaudio.package = pkgs.pulseaudioFull;
  #nixpkgs.config.pulseaudio = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
    wireplumber.enable = true;
  };

  # Enable Portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  # Enable resolved (needed by OpenVPN)
  services.resolved.enable = true;

  #services.flatpak.enable = true;

  # OpenVPN
  services.openvpn.servers = {
    euc = {
      autoStart = false;
      #TODO authUserPass = { username = "corin.lawson"; password = "..."; };
      config = '' config /etc/openvpn/client/euc.conf '';
    };
  };

  # Enable lorri
  services.lorri.enable = true;

  services.sshd.enable = true;
  hardware.uinput.enable = true;

  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    configFile = ''
      %users ALL=(ALL) NOPASSWD:${pkgs.physlock}/bin/physlock -l,NOPASSWD:${pkgs.physlock}/bin/physlock -L
    '';
  };

  security.polkit.enable = true;    

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users.users.corin = {
    isNormalUser = true;
    uid = 1000;
    group = "corin";
    extraGroups = [
      "adbusers"
      "audio"
      "bumblebee"
      "cdrom"
      "docker"
      "kvm"
      "libvirtd"
      "libvirt"
      "media"
      "networkmanager"
      "plugdev"
      "systemd-journal"
      "usb"
      "video"
      "disk"
      "wheel"
      "uinput"
    ];
  };
  users.groups.corin.gid = 1000;
  home-manager.users.corin = let
    lock = pkgs.writeShellScriptBin "lock.sh" ''
      set -ue

      screen=$(${pkgs.coreutils}/bin/mktemp -p /tmp lockscreen-XXXX)
      #trap "sudo ${pkgs.physlock}/bin/physlock -L; rm '$screen'*" EXIT
      trap "rm '$screen'*" EXIT

      outputs=$(
        (
          ${pkgs.sway}/bin/swaymsg --raw --type get_outputs \
            | jq --raw-output '
              .[]
              | "${pkgs.grim}/bin/grim -t jpeg -q 10 -g \"\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)\" - | ${pkgs.imagemagick}/bin/convert -sample \"\(.rect.width / 8)x\(.rect.height / 8)\" -modulate 100,70 - -sample \"\(.rect.width)x\(.rect.height)\" \"${./share/resources/shield.png}\" -geometry +\(.rect.width / 2 - 148)+\(.rect.height / 2 - 149) -composite '$screen'-\(.name).png & echo \"\(.name)\""';
          echo wait;
        ) | sh
      )
      #sudo ${pkgs.physlock}/bin/physlock -l
      for o in $outputs; do echo '--image '"$o:$screen-$o.png"; done | \
        ${pkgs.findutils}/bin/xargs ${pkgs.swaylock}/bin/swaylock \
          --ignore-empty-password \
          --show-failed-attempts \
          --color 000000 \
          --indicator-radius 164 \
          --indicator-thickness 30 \
          --font "${font.sansSerif}" \
          --font-size 20 \
          --ring-color '${theme.green}' \
          --line-color '000000CC' \
          --text-color '${theme.green}' \
          --inside-color '${theme.green}66' \
          --key-hl-color '${theme.blue}' \
          --bs-hl-color '${theme.red}' \
          --separator-color '000000CC' \
          --ring-clear-color '${theme.red}' \
          --line-clear-color '000000CC' \
          --text-clear-color '${theme.red}' \
          --inside-clear-color '${theme.red}66' \
          --ring-caps-lock-color '${theme.yellow}' \
          --line-caps-lock-color '000000CC' \
          --text-caps-lock-color '${theme.yellow}' \
          --inside-caps-lock-color '${theme.yellow}66' \
          --caps-lock-key-hl-color '${theme.blue}' \
          --caps-lock-bs-hl-color '${theme.red}' \
          --ring-ver-color '${theme.blue}' \
          --line-ver-color '000000CC' \
          --text-ver-color '${theme.blue}' \
          --inside-ver-color '${theme.blue}66' \
          --ring-wrong-color '${theme.red}' \
          --line-wrong-color '000000CC' \
          --text-wrong-color '${theme.red}' \
          --inside-wrong-color '${theme.red}66'
    '';
  in { config, pkgs, ... }: {
    home.stateVersion = "18.09";

    home.packages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      xwayland # for legacy apps
      mako # notification daemon
      kitty # Kitty is the default terminal in the config
      wofi # Dmenu replacement
      wdisplays # xrandr replacement
      kanshi # autorandr replacement
      waybar # i3bar replacement
      flameshot # grim # scrot replacement
    ];
    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      systemd.enable = true;
      config = let
        card = "0";
        modifier = "Mod4";
        wofiStyle = pkgs.writeText "wofi-style.css" ''
	  @define-color placeholder_text_color ${theme.base01};

	  #window, #outer-box, #inner-box, #scroll {
	    border: none;
	    background-color: transparent;
	    font-family: "${font.sansSerif}";
	    font-size: 20pt;
	    color: ${theme.base03};
	  }

	  entry.search {
	    color: ${theme.base03};
	    height: 72px;
	    border-radius: 40px;
	    border: 16px solid ${theme.base2};
	    background-color: ${theme.base3};
	    margin-bottom: 16px;
	    padding: 6px 16px;
	  }
	  .search:focus {
	    box-shadow: none;
	  }

	  .entry {
	    color: ${theme.base03};
	    border-radius: 40px;
	    background-color: ${theme.base3};
	    padding: 6px 16px;
	  }

	  #entry {
	    border-radius: 40px;
	    padding: 0;
	    border: 6px solid transparent;
	  }
	  #entry:focus {
	    outline: none;
	    background-color: transparent;
	    border: 6px solid ${theme.cyan};
	  }

	  #selected #text {
	    color: ${theme.base03};
	  }
        '';
      in {
        modifier = "${modifier}";
        fonts = {
          names = [ font.monospace ];
          size = 8.0;
        };
        terminal = "${pkgs.kitty}/bin/kitty";
        input."type:touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
          tap_button_map = "lrm";
          middle_emulation = "enabled";
          dwt = "disabled";
        };
        output."*".bg = "${./share/background.png} fill";
        keybindings = lib.mkOptionDefault {
          "${modifier}+Shift+Return" = "exec ${pkgs.kitty}/bin/kitty";
          "${modifier}+Shift+c" = "kill";
          "${modifier}+p" = "exec ${pkgs.wofi}/bin/wofi --show run --lines 5 --hide-scroll --style ${wofiStyle}";
          "${modifier}+Shift+p" = "exec ${pkgs.wofi}/bin/wofi --show input --modi 'input:i3-input' --lines 5 --hide-scroll --style ${wofiStyle}";

          "${modifier}+v" = "split h";
          "${modifier}+s" = "split v";
          "${modifier}+space" = "fullscreen toggle";

          "${modifier}+t" = "layout tabbed";
          "${modifier}+g" = "layout stacking";
          "${modifier}+b" = "layout toggle split";

          "${modifier}+Shift+plus" = "floating toggle";
          "${modifier}+f" = "focus mode_toggle";

          "${modifier}+d" = "focus child";

          "${modifier}+Tab" = "workspace back_and_forth";

          "${modifier}+z" = "reload";
          "${modifier}+q" = "restart";
          "${modifier}+Shift+q" = "exec ${pkgs.sway}/bin/swaynag --font '${font.monospace} 14' --type warning --background '${theme.yellow}' --border-bottom '${theme.yellow}CC' --text '${theme.base03}' --button-gap 0 --button-border-size 0 --button-padding 8 --message 'Do you want to exit sway?' --button 'Yes' '${pkgs.sway}/bin/swaymsg exit' --dismiss-button 'No'";
          "${modifier}+x" = "exec ${lock}/bin/lock.sh ";
          # audio volume control
          "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 -5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 +5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute 0 toggle; exec ${pkgs.alsaUtils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '\\[off\\]' && ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1) || ${pkgs.volnoti}/bin/volnoti-show -m";
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
          "Shift+XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 100%";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 3%-";
          "Shift+XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 0%";
          # screen capture
          "Print"                   = ''exec XDG_SESSION_TYPE=x11 ${pkgs.flameshot}/bin/flameshot gui --path \"''${HOME}/Pictures/screenshot-$(date --iso-8601=seconds).png\"'';
          "Shift+Print"             = ''exec XDG_SESSION_TYPE=x11 ${pkgs.flameshot}/bin/flameshot gui --raw | ${pkgs.wl-clipboard}/bin/wl-copy'';
          "${modifier}+Print"       = ''exec XDG_SESSION_TYPE=x11 ${pkgs.flameshot}/bin/flameshot gui --path \"''${HOME}/Pictures/screenshot-$(date --iso-8601=seconds).png\"'';
          "${modifier}+Shift+Print" = ''exec XDG_SESSION_TYPE=x11 ${pkgs.flameshot}/bin/flameshot gui --raw | ${pkgs.wl-clipboard}/bin/wl-copy'';
          #"Print" = "exec ${./share/scripts/scrot-m.sh}";
          #"$mod+Print" = "exec ${./share/scripts/scrot-d.sh}";
          #"Shift+Print" = "exec ${./share/scripts/scrot-u.sh}";
          #"$mod+Shift+Print" = "exec ${./share/scripts/scrot-du.sh}";
        };

        modes.resize = let
          step = "2";
          jump = "5";
        in {
          "Left"              = "resize shrink width  ${step} px or ${step} ppt";
          "${modifier}+Left"  = "resize shrink width  ${jump} px or ${jump} ppt";
          "h"                 = "resize shrink width  ${step} px or ${step} ppt";
          "${modifier}+h"     = "resize shrink width  ${jump} px or ${jump} ppt";
          "Right"             = "resize grow   width  ${step} px or ${step} ppt";
          "${modifier}+Right" = "resize grow   width  ${jump} px or ${jump} ppt";
          "l"                 = "resize grow   width  ${step} px or ${step} ppt";
          "${modifier}+l"     = "resize grow   width  ${jump} px or ${jump} ppt";
          "Up"                = "resize shrink height ${step} px or ${step} ppt";
          "${modifier}+Up"    = "resize shrink height ${jump} px or ${jump} ppt";
          "k"                 = "resize shrink height ${step} px or ${step} ppt";
          "${modifier}+k"     = "resize shrink height ${jump} px or ${jump} ppt";
          "Down"              = "resize grow   height ${step} px or ${step} ppt";
          "${modifier}+Down"  = "resize grow   height ${jump} px or ${jump} ppt";
          "j"                 = "resize grow   height ${step} px or ${step} ppt";
          "${modifier}+j"     = "resize grow   height ${jump} px or ${jump} ppt";
          "Return" = "mode default";
          "Escape" = "mode default";
          "${modifier}+Return" = "mode default";
          "${modifier}+r" = "mode default";
        };

        colors.focused = {
          border      = "${theme.base1}";
          background  = "${theme.base1}";
          text        = "${theme.base03}";
          indicator   = "${theme.violet}";
          childBorder = "${theme.base2}";
        };
        colors.unfocused = {
          border      = "${theme.base02}";
          background  = "${theme.base02}";
          text        = "${theme.base1}";
          indicator   = "${theme.base01}";
          childBorder = "${theme.base01}";
        };
        colors.focusedInactive = {
          border      = "${theme.base02}";
          background  = "${theme.base02}";
          text        = "${theme.base2}";
          indicator   = "${theme.violet}";
          childBorder = "${theme.base01}";
        };
        colors.urgent = {
          border      = "${theme.magenta}";
          background  = "${theme.magenta}";
          text        = "${theme.base3}";
          indicator   = "${theme.red}";
          childBorder = "${theme.violet}";
        };

        window = {
          titlebar = false;
          border = 0;
        };

        bars = [
          {
            fonts = {
              names = [ font.monospace ];
              size = 14.0;
            };
            position = "bottom";
            command = "true"; # using programs.waybar.systemd.enable
            colors.background = "${theme.bg}";
            colors.focusedWorkspace = {
              border     = "${theme.base3}";
              background = "${theme.green}";
              text       = "${theme.base3}";
            };
            colors.activeWorkspace = {
              border     = "${theme.base3}";
              background = "${theme.violet}";
              text       = "${theme.base3}";
            };
            colors.inactiveWorkspace = {
              border     = "${theme.base01}";
              background = "${theme.base1}";
              text       = "${theme.base03}";
            };
            colors.urgentWorkspace = {
              border     = "${theme.magenta}";
              background = "${theme.magenta}";
              text       = "${theme.base3}";
            };
          }
        ];

        startup = [
          { command = "systemctl --user restart kanshi.service"; always = true; }
        ];
      };
      #extraConfig = ''
      #  exec_always {
      #    gsettings set org.gnome.desktop.interface gtk-theme NumixSolarizedDarkBlue
      #    gsettings set org.gnome.desktop.interface icon-theme Pop
      #  }
      #'';
    };

    home.file = {
      ".config/xdg-desktop-portal-wlr/config".text = ''
        [screencast]
        output=
        chooser_cmd=${pkgs.wofi}/bin/wofi -d -n --prompt 'Select screen to output'
        chooser_type=dmenu
      '';
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = [
        {
          position = "bottom";
          margin = "0";
          modules-left = [
            "sway/mode"
            "sway/workspaces"
            "custom/arrow0"
            "sway/window"
          ];
          modules-center = [
            #"sway/window"
          ];
          modules-right = [
            "custom/arrow2"
            "memory"
            "custom/arrow3"
            "cpu"
            "custom/arrow4"
            "network"
            "custom/arrow5"
            "temperature"
            "custom/arrow6"
            "battery"
            "custom/arrow7"
            "tray"
            "clock#date"
            "custom/arrow8"
            "clock#time"
          ];

          modules."battery" = {
            interval = 1;
            states = {
              warning = 30;
              critical = 15;
            };
            format = " {capacity}%";
            format-discharging = "{icon} {capacity}%";
            format-icons = [ "" "" "" "" "" ];
            tooltip = false;
          };

          modules."clock#time" = {
            interval = 10;
            format = "{:%H:%M}";
            tooltip = false;
          };

          modules."clock#date" = {
            interval = 20;
            format = "{:%e %b %Y}";
            #tooltip-format = "{:%e %B %Y}";
            tooltip = false;
          };

          modules."cpu" = {
            interval = 5;
            tooltip = false;
            format = " {usage}%";
            states = {
              warning = 70;
              critical = 90;
            };
          };

          modules."memory" = {
            interval = 5;
            format = " {}%";
            states = {
              warning = 70;
              critical = 90;
            };
          };

          modules."network" = {
            interval = 5;
            format-wifi = " {essid} ({signalStrength}%)";
            #format-ethernet = " {ifname}: {ipaddr}/{cidr}";
            format-ethernet = " {ifname}";
            format-disconnected = "睊";
            tooltip-format = "{ifname}: {ipaddr}";
            #tooltip = false;
            on-click = "echo -n {ipaddr} | ${pkgs.xsel}/bin/xsel --clipboard";
          };

          modules."sway/mode" = {
            format = "<span style=\"italic\"> {}</span>";
            tooltip = false;
          };

          modules."sway/window" = {
            format = "{}";
            max-length = 30;
            tooltip = false;
          };

          modules."sway/workspaces" = {
            all-outputs = false;
            disable-scroll = false;
            format = "{name}";
            format-icons = {
              "1:www" = "";
              "2:mail" = "";
              "3:editor" = "";
              "4:terminals" = "";
              urgent = "";
              focused = "";
              default = "";
            };
          };

          modules."temperature" = {
            critical-threshold = 90;
            interval = 5;
            format = "{icon} {temperatureC}°";
            format-icons = [ "" "" "" "" "" ];
            tooltip = false;
          };

          modules."tray" = {
            "icon-size" = 21;
          };

          modules."custom/arrow0" = {
            "format" = "";
            "tooltip" = false;
          };

          modules."custom/arrow2" = {
            "format" = "";
            "tooltip" = false;
          };

          modules."custom/arrow3" = {
            "format" = "";
            "tooltip" = false;
          };

          modules."custom/arrow4" = {
            "format" = "";
            "tooltip" = false;
          };

          modules."custom/arrow5" = {
            "format" = "";
            "tooltip" = false;
          };

          modules."custom/arrow6" = {
            "format" = "";
            "tooltip" = false;
          };

          modules."custom/arrow7" = {
            "format" = "";
            "tooltip" = false;
          };

          modules."custom/arrow8" = {
            "format" = "";
            "tooltip" = false;
          };
        }
      ];
      style = ''
        @keyframes blink-fg-warning {
            to {
                color: @warning;
            }
        }

        @keyframes blink-fg-critical {
            to {
                color: @critical;
            }
        }

        @keyframes blink-bg-warning {
            70% {
                color: @light;
            }

            to {
                color: @light;
                background-color: @warning;
            }
        }

        @keyframes blink-bg-critical {
            70% {
              color: @light;
            }

            to {
                color: @light;
                background-color: @critical;
            }
        }

        /* COLORS */

        @define-color light ${theme.base2};
        @define-color dark ${theme.base03};
        @define-color warning ${theme.orange};
        @define-color critical ${theme.red};
        @define-color mode ${theme.blue};
        @define-color workspaces ${theme.blue};
        @define-color workspacesfocused ${theme.cyan};
        @define-color network ${theme.magenta};
        @define-color memory ${theme.base03};
        @define-color cpu ${theme.base02};
        @define-color temp ${theme.yellow};
        @define-color battery ${theme.green};
        @define-color date ${theme.cyan};
        @define-color time ${theme.blue};

        /* Reset all styles */
        * {
          border: none;
          border-radius: 0;
          min-height: 0;
          margin: 0;
          padding: 0;
        }

        /* The whole bar */
        #waybar {
          background: ${theme.bg};
          color: @light;
          font-family: ${font.monospace}, monospace;
          font-size: 10pt;
          font-weight: bold;
        }

        /* Each module */
        #battery,
        #clock,
        #cpu,
        #custom-layout,
        #memory,
        #mode,
        #network,
        #temperature,
        #tray {
          padding-left: 10px;
          padding-right: 10px;
        }

        /* Each module that should blink */
        #mode,
        #memory,
        #temperature,
        #battery {
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        /* Each critical module */
        #memory.critical,
        #cpu.critical {
          color: @critical;
        }
        #temperature.critical,
        #battery.critical {
          background-color: @critical;
        }

        /* Each critical that should blink */
        #mode,
        #battery.critical.discharging {
          animation-name: blink-bg-critical;
          animation-duration: 2s;
        }
        #memory.critical,
        #temperature.critical {
          animation-name: blink-fg-critical;
          animation-duration: 2s;
        }

        /* Each warning */
        #memory.warning,
        #cpu.warning {
          color: @warning;
        }
        #network.disconnected,
        #temperature.warning,
        #battery.warning {
          background-color: @warning;
        }

        /* Each warning that should blink */
        #battery.warning.discharging {
          animation-name: blink-bg-warning;
          animation-duration: 3s;
        }

        /* And now modules themselves in their respective order */

        #mode { /* Shown current Sway mode (resize etc.) */
          background: @mode;
        }

        /* Workspaces stuff */
        #workspaces button {
          font-weight: bold; /* Somewhy the bar-wide setting is ignored*/
          padding-left: 5px;
          padding-right: 5px;
          background: @workspaces;
        }

        #workspaces button.focused {
          background: @workspacesfocused;
        }

        #workspaces button.urgent {
          background: @critical;
        }

        #window {
          margin-right: 40px;
          margin-left: 40px;
        }

        #network {
          background: @network;
        }

        #memory {
          background: @memory;
        }

        #cpu {
          background: @cpu;
        }

        #temperature {
          background: @temp;
        }

        #battery {
          background: @battery;
        }

        #tray {
          background: @date;
        }

        #clock.date {
          background: @date;
        }

        #clock.time {
          background: @time;
        }

        #custom-arrow0 {
          font-size: 16px;
          color: @workspaces;
          background: transparent;
        }

        #custom-arrow2 {
          font-size: 16px;
          background: transparent;
          color: @memory;
        }

        #custom-arrow3 {
          font-size: 16px;
          background: @memory;
          color: @cpu;
        }

        #custom-arrow4 {
          font-size: 16px;
          background: @cpu;
          color: @network;
        }

        #custom-arrow5 {
          font-size: 16px;
          background: @network;
          color: @temp;
        }

        #custom-arrow6 {
          font-size: 16px;
          background: @temp;
          color: @battery;
        }

        #custom-arrow7 {
          font-size: 16px;
          background: @battery;
          color: @date;
        }

        #custom-arrow8 {
          font-size: 16px;
          background: @date;
          color: @time;
        }
      '';
    };

    programs.vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        ms-vsliveshare.vsliveshare
        github.copilot
        yzhang.markdown-all-in-one
        bbenoist.nix
        golang.go
        angular.ng-template
      ];
    };

    services.gnome-keyring.enable = true;

    services.kanshi = {
      enable = true;
      # Run `swaymsg -t get_outputs` to see present outputs
      profiles.okx-hub.outputs = [
        {
          status = "enable";
          criteria = "BenQ Corporation BenQ GL2460 R7E01381SL0";
          mode = "1920x1080";
          position = "0,0";
        }
        {
          status = "enable";
          criteria = "BenQ Corporation BenQ GL2460 46E01111SL0";
          mode = "1920x1080";
          position = "1920,0";
        }
        {
          status = "enable";
          criteria = "eDP-1";
          mode = "1920x1200";
          position = "1920,1080";
        }
      ];
      profiles.dell-hub.outputs = [
        {
          status = "enable";
          criteria = "DP-1";
          mode = "1920x1080";
          position = "0,0";
        }
        {
          status = "enable";
          criteria = "eDP-1";
          mode = "1920x1200";
          position = "0,1080";
        }
      ];
    };

    systemd.user.services.sunshine = {
      Unit = {
        Description = "Sunshine self-hosted game stream host for Moonlight.";
        StartLimitIntervalSec = "500";
        StartLimitBurst = "5";
      };

      Service = {
        ExecStart = "${pkgs.sunshine}/bin/sunshine";
        Environment = "PATH=${
          lib.makeBinPath (with pkgs; [
            coreutils findutils gnugrep gnused xorg.xrandr util-linux pulseaudio
            steam prismlauncher
          ])
        }";
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install = { WantedBy = [ "xdg-desktop-autostart.target" ]; };
    };

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        BindsTo = [ "sway-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {
        WantedBy = [ "sway-session.target" ];
      };
    };

    systemd.user.services.swayidle = {
      Unit = {
        Description = "Idle manager for Wayland";
        BindsTo = [ "sway-session.target" ];
      };
      Service = let
        swayidleStart = pkgs.writeShellScript "swayidle-start.sh" ''
          ${pkgs.swayidle}/bin/swayidle \
            timeout  300 '${pkgs.brightnessctl}/bin/brightnessctl --save set 10%' \
                  resume '${pkgs.brightnessctl}/bin/brightnessctl --restore' \
            timeout  600 ${lock}/bin/lock.sh \
            timeout 1200 '${pkgs.sway}/bin/swaymsg "output * dpms off"' \
                  resume '${pkgs.sway}/bin/swaymsg "output * dpms on"' \
            timeout 1800 '${pkgs.sway}/bin/swaymsg "output * dpms on"; \
                          ${pkgs.brightnessctl}/bin/brightnessctl --restore; \
                          ${pkgs.systemd}/bin/systemctl suspend' \
            before-sleep ${lock}/bin/lock.sh \
            lock ${lock}/bin/lock.sh
        '';
      in {
        Type = "simple";
        ExecStart = "${swayidleStart}";
        RestartSec = 3;
        Restart = "always";
      };
      Install = {
        WantedBy = [ "sway-session.target" ];
      };
    };

    systemd.user.services.volnoti = {
      Unit = {
        Description = "Lightweight volume notification daemon";
        BindsTo = [ "sway-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.volnoti}/bin/volnoti -n";
        RestartSec = 3;
        Restart = "always";
      };
      Install = {
        WantedBy = [ "sway-session.target" ];
      };
    };

    services.mako = {
      enable = true;
      iconPath = "/run/current-system/sw/share/icons/hicolor:/run/current-system/sw/share/pixmaps";
      textColor = "${theme.base02}ff";
      backgroundColor = "${theme.base3}ff";
      progressColor = "over ${theme.base1}66";
      borderColor = "${theme.base2}ff";
      borderRadius = 6;
      borderSize = 4;
      padding = "10";
      margin = "14";
      font = "${font.sansSerif} 14";
    };

    xresources.extraConfig = builtins.readFile (
      pkgs.fetchFromGitHub {
        owner = "solarized";
        repo = "xresources";
        rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
        sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
      } + "/Xresources.dark"
    );

    programs.alacritty = {
      enable = true;
      settings = {
        window.dynamic_title = true;
        window.dimensions = {
          columns = 80;
          lines = 24;
        };
        window.padding = { x = 2; y = 2; };
        window.dynamic_padding = false;
        window.decorations = "none";
        window.startup_mode = "Maximized";
        window.decorations_theme_variant = "Dark";
        scrolling.history = 10000;
        font.normal.family = "${font.monospace}";
        font.offset = { x = 0; y = 0; };
        font.glyph_offset = { x = 0; y = 0; };
        draw_bold_text_with_bright_colors = false;
        colors.primary = {
          background = "${theme.bg}";
          foreground = "${theme.base0}";
        };
        colors.cursor = {
          text = "#000000";
          cursor = "#ffffff";
        };
        colors.normal = {
          black   = "${theme.base03}";
          red     = "${theme.red}";
          green   = "${theme.green}";
          yellow  = "${theme.yellow}";
          blue    = "${theme.blue}";
          cyan    = "${theme.cyan}";
          white   = "${theme.base2}";
          magenta = "${theme.magenta}";
        };
        colors.bright = {
          black   = "${theme.base03}";
          red     = "${theme.orange}";
          green   = "${theme.base01}";
          yellow  = "${theme.base00}";
          blue    = "${theme.base0}";
          magenta = "${theme.violet}";
          cyan    = "${theme.base1}";
          white   = "${theme.base3}";
        };
        bell.animation = "EaseOut";
        bell.color = "${theme.base3}";
        bell.command = {
          program = "${pkgs.alsaUtils}/bin/aplay";
          args = [ "--samples=14500" ./share/bell.wav ];
        };
      };
    };

    programs.kitty = {
      enable = true;
      font.name = "${font.monospace}";
      settings = {
        # Set the initial window size (in cells)
        initial_window_width  = 80;
        initial_window_height = 24;

        # Set the padding around the text area
        padding_left = "2px";
        padding_top = "2px";
        padding_right = "2px";
        padding_bottom = "2px";

        # Disable dynamic padding
        dynamic_padding = false;

        # Set the window decoration
        hide_window_decorations = true;

        # Set the start-up mode
        start_up_mode = "maximized";

        # Set scrollback lines
        scrollback_lines = 10000;

        # Set the font family and size
        font_family = "${font.monospace}";
        # In kitty, the font size is not directly set in px, so you may adjust this value as needed
        font_size = "11.0";

        # Disable drawing bold text with bright colors
        draw_bold_text_with_bright_colors = false;

        # Set colors
        background = "${theme.bg}";
        foreground = "${theme.base0}";
        cursor = "${theme.base3}";
        cursor_text_color = "#000000";

        # Define color palette
        color0  = "${theme.base03}";
        color1  = "${theme.red}";
        color2  = "${theme.green}";
        color3  = "${theme.yellow}";
        color4  = "${theme.blue}";
        color5  = "${theme.magenta}";
        color6  = "${theme.cyan}";
        color7  = "${theme.base2}";
        color8  = "${theme.base03}";
        color9  = "${theme.orange}";
        color10 = "${theme.base01}";
        color11 = "${theme.base00}";
        color12 = "${theme.base0}";
        color13 = "${theme.violet}";
        color14 = "${theme.base1}";
        color15 = "${theme.base3}";

        # Kitty does not support bell animations, but it does support changing the bell color
        # and running a command when the bell rings
        bell_border_color = "${theme.base3}";
        enable_audio_bell = false;
        command_on_bell = "${pkgs.alsaUtils}/bin/aplay --samples=14500 ${./share/bell.wav}";
      };
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      history.extended = true;
      oh-my-zsh.enable = true;
      oh-my-zsh.plugins = [ "vi-mode" "git" "sudo" "adb" "per-directory-history" ];
      #oh-my-zsh.theme = "phiware";
      #oh-my-zsh.custom = "${./share/oh-my-zsh}";
      shellAliases = {
        nix-shell = ''nix-shell --command "$SHELL"'';
      };
      localVariables = rec {
        LOCALE_ARCHIVE = "$HOME/.nix-profile/lib/locale/locale-archive";
        GOPATH = "$(go env GOPATH)";
        GOPRIVATE = "github.com/transurbantech";
        GONOSUMDB = "${GOPRIVATE}";
      };
      initExtraFirst = ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh" ]]; then
          source "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh"
        fi
      '';
      initExtra = ''
         [[ "$TERM" == "linux" ]] && setfont "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz"

         complete -C '${pkgs.awscli2}/bin/aws_legacy_completer' aws

         source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
         source ${./share/p10k.zsh}
      '';
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    # This is for vim; are you looking for neovim?
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-surround
        vim-repeat
        vim-fugitive
        vim-sleuth
        vim-speeddating
        vim-commentary
        vim-vinegar
        emmet-vim
        vim-colors-solarized
        vim-airline
        vim-airline-themes
        vim-dispatch
        rainbow_parentheses
        vim-clojure-static
        vim-clojure-highlight
        vim-sexp
        vim-sexp-mappings-for-regular-people
        vim-go
        rust-vim
        tagbar
        vim-easytags
        syntastic
        webapi-vim
        plantuml-syntax
        goyo-vim limelight-vim
        orgmode
        LanguageTool-nvim
        vim-wordy
        # TODO: vim-scripts/DrawIt
        # TODO: atimholt/spiffy_foldtext
      ];
      settings = {
        background = "dark";
        directory = [ "$HOME/.vim/swapfiles" ];
        expandtab = true;
      };
      extraConfig = ''
        set nocompatible
        let mapleader=" "
        set termencoding=utf-8 encoding=utf-8
        filetype plugin indent on
        syntax enable
        colorscheme solarized
        let g:airline_theme='solarized'
        let g:airline_solarized_bg='dark'
        let g:airline_powerline_fonts = 1
        set t_Co=16
        nmap <F8> :TagbarToggle<CR>

        " Search files in subdirs, recursively
        set path+=**

        " Syntastic
        set statusline+=%#warningmsg#
        set statusline+=%{SyntasticStatuslineFlag()}
        set statusline+=%*
        let g:syntastic_always_populate_loc_list = 1
        let g:syntastic_auto_loc_list = 1
        let g:syntastic_check_on_open = 1
        let g:syntastic_check_on_wq = 0

        " SpiffyFoldtext
        if has('multi_byte')
          let g:SpiffyFoldtext_format = "%c{ }  %<%f{ }╡ %4n lines ╞═%l{╤═}"
        else
          let g:SpiffyFoldtext_format = "%c{ }  %<%f{ }| %4n lines |=%l{/=}"
        endif
        highlight Folded term=NONE cterm=NONE ctermfg=12 ctermbg=0 guifg=Cyan guibg=DarkGrey

        " Go
        let g:go_fmt_command = '${pkgs.go}/share/go/bin/gofmt'
        let g:go_fmt_options = '-s'

        " Rust
        let g:rustfmt_autosave = 1
        let g:rust_clip_command = '${pkgs.xsel}/bin/xsel --clipboard'
        au FileType rust set foldmethod=syntax

        " Emmet
        let g:user_emmet_expandabbr_key='<Tab>'
        imap <expr> <tab> emmet#expandAbbrIntelligent("\<tab>")

        " Clojure
        au FileType clojure RainbowParenthesesToggle
        au Syntax clojure RainbowParenthesesLoadRound
        au Syntax clojure RainbowParenthesesLoadSquare
        au Syntax clojure RainbowParenthesesLoadBraces

        " Text width
        set colorcolumn=+1
      '';
    };

    programs.neovim = {
      enable = true;
      withNodeJs = true;

      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      coc = {
        enable = true;
        package = unstable.vimPlugins.coc-nvim;
        settings = {
          "coc.preferences.watchmanPath" = "${pkgs.watchman}/bin/watchman";
        };
      };

      plugins = let
        omnisharp-vim = pkgs.vimUtils.buildVimPlugin {
          name = "omnisharp-vim";
          src = pkgs.fetchFromGitHub {
            owner = "OmniSharp";
            repo = "omnisharp-vim";
            rev = "f9c5d3e3375e8b5688a4506e813cb21bdc7329b1";
            hash = "sha256-z3Dgrm9pNWkvfShPmB9O8TqpY592sk1W722zduOSing=";
          };
        };
      in with pkgs.vimPlugins; [
        vim-surround
        vim-repeat
        vim-fugitive
        vim-sleuth
        vim-speeddating
        vim-commentary
        vim-vinegar
        emmet-vim
        vim-colors-solarized
        vim-airline
        vim-airline-themes
        # vim-dispatch
        # tagbar
        goyo-vim limelight-vim
        # orgmode
        LanguageTool-nvim
        vim-wordy
        vim-emoji
        venn-nvim
        unstable.vimPlugins.neorg
        unstable.vimPlugins.nvim-treesitter
        unstable.vimPlugins.nvim-treesitter-parsers.norg

        vim-nix
        vim-startify
        vim-go
        typescript-vim
        omnisharp-vim
        #omnisharp-extended-lsp-nvim
        coc-explorer
        coc-git
        coc-html
        coc-emmet
        coc-json
        coc-go
        coc-tsserver
        coc-eslint
        coc-yaml
        coc-prettier
        coc-tsserver

        vimspector
        ale

        # AI code-completion
        unstable.vimPlugins.copilot-vim
	#unstable.vimPlugins.codeium-vim
      ];
      extraConfig = ''
        let mapleader=" "
        "set termencoding=utf-8 encoding=utf-8
        filetype plugin indent on
        "syntax enable
        colorscheme solarized
        let g:airline_theme='solarized'
        let g:airline_solarized_bg='dark'
        let g:airline_powerline_fonts = 1
        "set t_Co=16
        "nmap <F8> :TagbarToggle<CR>

        " Text width
        set colorcolumn=+1

        " OmniSharp (language server)
        let g:OmniSharp_server_path = '${unstable.omnisharp-roslyn}/bin/OmniSharp'
        let g:OmniSharp_log_dir = '${config.home.homeDirectory}/.local/share/omnisharp-vim/log'
        let g:ale_fixers = { 'cs': ['remove_trailing_lines', 'trim_whitespace', 'dotnet-format']}
        let g:ale_fix_on_save = 1
        autocmd FileType cs nmap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)
        autocmd FileType cs nmap <silent> <buffer> gr <Plug>(omnisharp_find_usages)
        autocmd FileType cs nmap <silent> <buffer> gi <Plug>(omnisharp_find_implementations)
        autocmd FileType cs nmap <silent> <buffer> gy <Plug>(omnisharp_go_to_type_definition)
        autocmd FileType cs nmap <silent> <buffer> <Leader>os= <Plug>(omnisharp_code_format)
        augroup FormatAutogroup
          autocmd!
          autocmd BufWritePre *.cs :OmniSharpCodeFormat
        augroup END

        " CoC
        " GoTo code navigation.
        nmap <silent> gd <Plug>(coc-definition)
        nmap <silent> gy <Plug>(coc-type-definition)
        nmap <silent> gi <Plug>(coc-implementation)
        nmap <silent> gr <Plug>(coc-references)
        " Use K to show documentation in preview window.
        nnoremap <silent> K :call ShowDocumentation()<CR>
        function! ShowDocumentation()
          if CocAction('hasProvider', 'hover')
            call CocActionAsync('doHover')
          else
            call feedkeys('K', 'in')
          endif
        endfunction
        " Symbol renaming.
        nmap <leader>rn <Plug>(coc-rename)
        " Apply AutoFix to problem on the current line.
        nmap <leader>qf  <Plug>(coc-fix-current)
        " Run the Code Lens action on the current line.
        nmap <leader>cl  <Plug>(coc-codelens-action)
        " Custom Jump to definition, i.e. <C-]>
        set tagfunc=CocTagFunc
      '';
      extraLuaConfig = ''
        require("neorg").setup {
          load = {
            ["core.defaults"] = {},
            ["core.dirman"] = {
              config = {
                workspaces = {
                  notes = "~/Documents/notes",
                  journal = "~/Documents/journal",
                  blogs = "~/Documents/blogs",
                },
              },
            },
            ["core.journal"] = {
              config = {
                journal_folder = "",
                workspace = "journal",
              },
            },
            ["core.concealer"] = {
              config = {
                icons = {
                  todo = {
                    undone = {
                      icon = " ",
                    },
                    recurring = {
                      icon = "󰃮",
                    },
                    cancelled = {
                      icon = "󰩺",
                    },
                    pending = {
                      icon = "󰔟",
                    },
                    on_hold = {
                      icon = "󰏤",
                    },
                    uncertain = {
                      icon = "?",
                    },
                    urgent = {
                      icon = "!",
                    },
                  },
                },
              },
            },
          },
        }
      '';
    };

    home.file.".cvsignore".source = ./cvsignore;
    home.file.".local/share/gitconfig/hooks/prepare-commit-msg" = {
      executable = true;
      source = "${(pkgs.callPackage ./git-hooks/prepare-commit-msg { })}/bin/prepare-commit-msg";
    };

    programs.git = {
      enable = true;
      lfs.enable = true;
      userName = "Corin Lawson";
      aliases = {
        amend = "commit --amend --signoff";
        sign = "commit --signoff --gpg-sign";
        fixup = "commit --fixup";
        autosquash = "rebase --interactive --autosquash";
        force-push = "push --force";
        log-all = "log --all --graph --decorate --oneline";
      };
      extraConfig = {
        core = {
          excludesfile = "${./cvsignore}";
          hooksPath = "${config.home.homeDirectory}/.local/share/gitconfig/hooks";
        };
        init = { defaultBranch = "main"; };
        push = { default = "current"; };
        pull = { rebase = true; };
        merge = { conflictStyle = "zdiff3"; };
        diff = { algorithm = "histogram"; };
        commit = {
          template = "${./share/gitconfig/commit-template}";
          verbose = true;
        };
        rebase = { updateRefs = true; };
        rerere = { enabled = true; };
        branch = { autosetupmerge = true; };
        includeIf = {
          "gitdir:**" = {
            path = "${./share/gitconfig/default}";
          };
          "hasconfig:remote.*.url:git@github.com:transurbantech/**" = {
            path = "${./share/gitconfig/transurban}";
          };
          "hasconfig:remote.*.url:https://github.com/transurbantech/**" = {
            path = "${./share/gitconfig/transurban}";
          };
          "hasconfig:remote.*.url:git@github.com:AustralianFinanceGroup/**" = {
            path = "${./share/gitconfig/versent}";
          };
          "hasconfig:remote.*.url:https://github.com/AustralianFinanceGroup/**" = {
            path = "${./share/gitconfig/versent}";
          };
          "hasconfig:remote.*.url:git@github.com:Versent/**" = {
            path = "${./share/gitconfig/versent}";
          };
          "hasconfig:remote.*.url:https://github.com/Versent/**" = {
            path = "${./share/gitconfig/versent}";
          };
        };
        url = {
          "git@github.com:au-phiware/" = {
            insteadOf = "https://github.com/au-phiware/";
          };
          "git@github.com:Versent/" = {
            insteadOf = "https://github.com/Versent/";
          };
          "git@github.com:AustralianFinanceGroup/" = {
            insteadOf = "https://github.com/AustralianFinanceGroup/";
          };
          "git@github.com:transurbantech/" = {
            insteadOf = "https://github.com/transurbantech/";
          };
          "https://au-phiware:a1654b37d47eaa726b10a30896e69ad99a4aefdc@github.com/" = {
            insteadOf = "https://github.com/";
          };
        };
        credential = {
          "https://github.com" = {
	    helper = ["" "!${pkgs.gh}/bin/gh auth git-credential"];
          };
          "https://gist.github.com" = {
	    helper = ["" "!${pkgs.gh}/bin/gh auth git-credential"];
          };
        };
        magithub = {
          online = false;
          status = {
            includeStatusHeader = false;
            includePullRequestsSection = false;
            includeIssuesSection = false;
          };
        };
      };
      delta = {
        enable = true;
        options = {
          theme = "Solarized (dark)";
        };
      };
    };

    programs.ssh.enable = true;
    programs.ssh.matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
      };
      "i-* mi-* tu-*-ec2-bastion" = {
        proxyCommand = "${(pkgs.callPackage ./pkgs/aws-ssm-ssh-proxycommand { })}/aws-ssm-ssh-proxycommand.sh %h %r %p";
        user = "ec2-user";
        extraOptions = {
          StrictHostKeyChecking = "no";
        };
      };
    };
  };

  #systemd.targets.sleep.enable = false;
  #systemd.targets.suspend.enable = false;
  #systemd.targets.hibernate.enable = false;
  #systemd.targets.hybrid-sleep.enable = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  #nixpkgs.config.permittedInsecurePackages = [
  #  "go-1.14.15"
  #];

  environment = {
    wordlist.enable = true;

    pathsToLink = [
      "/share/zsh"
      "/share/icons/hicolor"
      "/share/pixmaps"
    ];

    etc = {
      "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
        bluez_monitor.properties = {
          ["bluez5.enable-sbc-xq"] = true,
          ["bluez5.enable-msbc"] = true,
          ["bluez5.enable-hw-volume"] = true,
          ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
        }
      '';
    };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      displaylink
      thunderbolt bolt
      sof-firmware # Mic needs 1.6
      binutils
      pciutils
      usbutils
      moreutils
      ascii
      file
      tmux
      htop
      wget
      emacs
      gnumake
      git gitAndTools.delta
      mercurial
      jq
      tree
      gnupg
      zip
      unzip
      imagemagick
      zlib
      icu
      utillinux
      xdotool
      smartmontools
      cdrtools
      multipath-tools
      inotify-tools
      libnotify
      vim

      psmisc
      bind
      tcpdump
      bridge-utils
      inetutils
      openssl
      libvirt
      #virt-viewer virt-manager
      #qemu-utils qemu_kvm
      #win-virtio virtio-win
      dnsmasq
      spice win-spice
      docker-compose
      ansible
      #unstable.awscli2
      unstable.awscli2
      ssm-session-manager-plugin
      unstable.saml2aws
      kerberos
      libkrb5
      libsecret
      lttng-ust
      patchelf
      powershell
      thefuck
      rlwrap
      bc
      hexedit
      elinks

      # kubernetes-helm - Hold back to 2.13.1
      #(pkgs.kubernetes-helm.overrideAttrs (oldAttrs: {
      #  name = "kubernetes-helm-2.13.1";
      #  version = "2.13.1";
      #  src = fetchurl {
      #    url = "https://kubernetes-helm.storage.googleapis.com/helm-v2.13.1-linux-amd64.tar.gz";
      #    sha256 = "0nljk2y6h5bvjmc4x1knn1yb5gnikgdyvvc09dlj3jfnzhfpr5n1";
      #  };
      #}))

      unstable.nushell
      z-lua
      oh-my-zsh
      python-with-pkgs
      #python310Packages.flake8
      #python310Packages.powerline
      #python310Packages.pylint
      #(maven.overrideAttrs (oldAttrs: rec {
      #  name = "apache-maven-${version}";
      #  version = "3.5.4";
      #  src = fetchurl {
      #    url = "mirror://apache/maven/maven-3/${version}/binaries/${name}-bin.tar.gz";
      #    sha256 = "0kd1jzlz3b2kglppi85h7286vdwjdmm7avvpwgppgjv42g4v2l6f";
      #  };
      #}))
      (maven.override {
            jdk = jdk8;
          })
      #(go_1_13.overrideAttrs (oldAttrs: rec {
      #  name = "go-${version}";
      #  version = "1.13.4";
      #  src = fetchurl {
      #    url = "https://dl.google.com/go/go${version}.src.tar.gz";
      #    sha256 = "093n5v0bipaan0qqc02wash18r625y74r4zhmjwlc9zf8asfmnwm";
      #  };
      #}))
      unstable.go
      unstable.gotools
      unstable.gopls
      #go-swagger
      #(rstudioWrapper.override{ packages = with rPackages; [ devtools remotes dbplyr dplyr RProtoBuf profile ]; })
      protobuf
      bats
      grpc
      gcc
      rclone
      lm_sensors
      #(vim_configurable.override { python3 = python-with-pkgs; })
      languagetool
      proselint
      mdl
      universal-ctags
      gdb
      rustup
      glib
      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      lxappearance
      numix-solarized-gtk-theme
      pop-icon-theme
      gnome3.nautilus
      gnome3.gnome-keyring
      xsel
      gitAndTools.hub
      gh
      lastpass-cli
      _1password _1password-gui
      shellcheck
      watchman

      arandr
      alsa-ucm-conf
      alsa-firmware
      alsaUtils
      pavucontrol
      glxinfo
      freerdp
      zoom-us
      gnome.seahorse
      plantuml-c4

      surf
      spotify
      #unstable.teams
      firefox
      ungoogled-chromium
      brave
      unstable.microsoft-edge-beta
      gimp
      vlc
      obs-studio
      sox
      spectacle
      inkscape
      libreoffice
      pdftk
      cabextract
      yq
      qpdf
      libsForQt5.okular qpdfview
      wgetpaste
      feh
      scrot
      nodejs
      postgresql
      curl
      lshw
      efibootmgr
      google-drive-ocamlfuse
      ntfs3g
      lsof
      picom
      twmn
      volnoti
      rxvt_unicode-with-plugins
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      global
      discount
      #jetbrains.idea-community
      rnnoise-plugin
      #webcamoid

      #unstable.slack
      (callPackage ./pkgs/slack { })
      #(callPackage ./pkgs/pact { })

      prismlauncher
      airshipper
      wineWowPackages.waylandFull
      sunshine

      unstable.dotnet-sdk_8
      unstable.dotnet-runtime_8
      unstable.csharprepl
      azure-functions-core-tools
      #(callPackage ./pkgs/azure-functions-core-tools { })
      unstable.azure-cli
      terraform

      # Versent SOC2
      #cloudflare-warp

      #(callPackage ./pkgs/kosmik { inherit unstable; })
    ];

    sessionVariables = {
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_DBUS_REMOTE" = "1";
      "NIXOS_OZONE_WL" = "1";
      "GTK_USE_PORTAL" = "1";
      "EDITOR" = "vim";
    };

    variables = {
      #ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      TMPDIR = "/tmp";
      #DOCKER_MACHINE = "${networking.hostName}";
      #DOCKER_MACHINE_NAME = "${networking.hostName}";
      #DOCKER_HOST = "tcp://${networking.hostName}:2376";
      #DOCKER_TLS_VERIFY = "1";
      #DOCKER_CERT_PATH = "$HOME/.docker";
      # GPG_TTY = "$(tty)";
      XDG_PICTURES_DIR = "$HOME/Pictures";
      XDG_DOWNLOAD_DIR = "$HOME/Downloads";
      FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT = "1";
    };
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts
      terminus_font
      powerline-fonts
      nerdfonts
      (callPackage ./pkgs/monaspace { })
    ];
    fontconfig.defaultFonts.sansSerif = [ "${font.sansSerif}" ];
    fontconfig.defaultFonts.monospace = [ "${font.monospace}" ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.zsh.enable = true;
  programs.bash.enableCompletion = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  #programs.adb.enable = true;
  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  programs.steam.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      #extraOptions = "--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/certs/cert.pem --tlskey=/etc/docker/certs/key.pem --host tcp://0.0.0.0:2376";
    };
    #anbox.enable = true;
    libvirtd.enable = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable Bluetooth
  services.blueman.enable = true;

  # Enable Thunderbolt security levels
  services.hardware.bolt.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    22 80 443 14004 14005 25565
    47984 47989 47990 48010 # sunshine ports
  ];
  networking.firewall.allowedUDPPorts = [
    47998 47999 48000 48002 # sunshine ports
  ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
  system.autoUpgrade.enable = true;
}
