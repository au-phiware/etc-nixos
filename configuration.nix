# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:
let
  # nix-channel --add https://nixos.org/channels/nixos-unstable unstable
  unstable = import <unstable> { config.allowUnfree = true; };
  font = {
    monospace = "Cousine for Powerline";
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
  #python-with-pkgs = with pkgs; python39.withPackages (pypkgs: with pypkgs; [
  #  flake8
  #  msgpack
  #  powerline
  #  pynvim
  #  #pylint
  #]);
in
rec {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Something is using a broken python lib (libarcus)
  #nixpkgs.config.allowBroken = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.font = "${pkgs.powerline-fonts}/share/fonts/truetype/${font.monospace}.ttf";
  boot.loader.grub.backgroundColor = "${theme.base03}";
  boot.initrd.kernelModules = [ "i915" ];
  #boot.kernelPackages = unstable.linuxPackages_5_10;
  #boot.kernelPackages = pkgs.linuxPackages_5_9;
  boot.kernelParams = [
    #"snd-intel-dspcfg.dsp_driver=1" # "snd_hda_intel.dmic_detect=0" # Enable sound
    #"net.ifnames=0" # Allow wifi interface names longer than 15 chars
    #"intel_iommu=on" # Allow graphics passthru to VMs
    "i915.enable_fbc=1"
    "i915.enable_psr=2"
    "vconsole.keymap=us"
    "vconsole.font=ter-powerline-v24n"
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
  boot.zfs.extraPools = [ "gauss" ];
  #boot.blacklistedKernelModules = [ "snd-soc-dmic" ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostId = "15f562b8";
  networking.hostName = "gauss";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager = {
    enable = true;
    #insertNameservers = [ "172.27.0.2" ];
  };
  networking.extraHosts =
    ''
      192.168.122.21 vmware65
      192.168.122.240 DESKTOP-05NF3NK
      172.17.0.1 gauss.docker
      127.0.0.1 gauss
    '';

  #powerManagement.cpuFreqGovernor = "performance";
  powerManagement.cpuFreqGovernor = "powersave";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    #allowedTCPPorts = [
    #  22 80 443 14004 14005 25565
    #  3478 3479  # STUN/TURN TCP
    #  19302      # Google STUN
    #];
    allowedUDPPorts = [
      #30000
      #3478 3479  # STUN/TURN UDP
      19302      # Google STUN
    ];
    allowedUDPPortRanges = [
      #{ from = 49152; to = 65535; }  # WebRTC range
      { from = 32768; to = 60999; }  # WebRTC range
    ];
    # Ensure we're not blocking any outbound traffic
    extraCommands = ''
      # Clear all rules
      iptables -F

      # Allow established connections
      iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
      iptables -A INPUT -i lo -j ACCEPT

      # Allow outbound traffic
      iptables -P OUTPUT ACCEPT
      iptables -P INPUT ACCEPT

      # Allow all UDP traffic for testing
      iptables -A INPUT -p udp -j ACCEPT
      iptables -A OUTPUT -p udp -j ACCEPT
    '';
  };
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  #networking.enableIPv6 = false;
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  #networking.useDHCP = false;
  #networking.dhcpcd.wait = "background";
  #networking.interfaces.wlp0s20f3.useDHCP = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.supportedLocales = [ "en_AU.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  console = {
    font = "Lat2-Terminus16";
    #font = "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz";
    #font = "ter-powerline-v24n";
    keyMap = "us";
  };

  # Enable a Desktop Environment.
  #programs.niri.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
  };
  services.xserver.enable = true;
  #services.xserver.videoDrivers = [ "nvidia" ];
  #services.xserver.synaptics = {
  #  enable = true;
  #  scrollDelta = -50;
  #  twoFingerScroll = true;
  #  fingersMap = [ 1 3 2 ];
  #};
  services.displayManager = {
    defaultSession = "sway";
    autoLogin = {
      enable = true;
      user = "corin";
    };
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
  services.printing.enable = true;

  # Enable OctoPrint to print objects.
  #services.octoprint.enable = true;

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

  services.fwupd.enable = true;

  # NFS
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export                 192.168.122.0/24(rw,fsid=0,no_subtree_check)
    /export/datastore       192.168.122.0/24(rw,nohide,insecure,no_subtree_check)
  '';

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #media-session.config.bluez-monitor.rules = [
    #  {
    #    # Matches all cards
    #    matches = [ { "device.name" = "~bluez_card.*"; } ];
    #    actions = {
    #      "update-props" = {
    #        "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
    #        # mSBC is not expected to work on all headset + adapter combinations.
    #        "bluez5.msbc-support" = true;
    #        # SBC-XQ is not expected to work on all headset + adapter combinations.
    #        "bluez5.sbc-xq-support" = true;
    #      };
    #    };
    #  }
    #  {
    #    matches = [
    #      # Matches all sources
    #      { "node.name" = "~bluez_input.*"; }
    #      # Matches all outputs
    #      { "node.name" = "~bluez_output.*"; }
    #    ];
    #    actions = {
    #      "node.pause-on-idle" = false;
    #    };
    #  }
    #];
  };

  # Enable Portals
  xdg.portal.enable = true;

  # Enable resolved (needed by OpenVPN)
  services.resolved.enable = true;

  # Enable lorri
  services.lorri.enable = true;

  # Enable the OpenSSH daemon.
  services.sshd.enable = true;

  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # Display
  #hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics.enable = true;
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    nvidiaSettings = true;
  #  prime = {
  #    sync.enable = true;
  #    nvidiaBusId = "PCI:1:0:0";
  #    intelBusId = "PCI:0:2:0";
  #  };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    configFile = ''
      %users ALL=(ALL) NOPASSWD:${pkgs.physlock}/bin/physlock -l,NOPASSWD:${pkgs.physlock}/bin/physlock -L
      %wheel ALL=(ALL) NOPASSWD:${pkgs.util-linux}/bin/dmesg
    '';
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

  systemd.services.NetworkManager = {
    serviceConfig = {
      LimitNOFILE = 65536;
    };
  };

  #services.wyoming.faster-whisper.servers."${config.networking.hostName}-whisper" = {
  #  enable = true;
  #  uri = "tcp://0.0.0.0:10300";
  #  device = "auto";
  #  language = "en";
  #  model = "turbo";
  #};

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
      "wheel"
      "dialout"
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
            | ${pkgs.jq}/bin/jq --raw-output '
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
  in { pkgs, ... }: {
    home.packages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      xwayland # for legacy apps
      mako # notification daemon
      alacritty # Alacritty is the default terminal in the config
      wofi # Dmenu replacement
      wdisplays # xrandr replacement
      kanshi # autorandr replacement
      waybar # i3bar replacement
      grim # scrot replacement
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
        terminal = "${pkgs.alacritty}/bin/alacritty";
        input."type:touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
          tap_button_map = "lrm";
          middle_emulation = "enabled";
          dwt = "disabled";
        };
        output."*".bg = "${./share/background.png} fill";
        keybindings = lib.mkOptionDefault {
          "${modifier}+Shift+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
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
          # screen capture
          "${modifier}+Print"       = ''exec ${pkgs.grim}/bin/grim \"''${HOME}/Pictures/screenshot-$(date --iso-8601=seconds).png\"; exec ${pkgs.alsa-utils}/bin/aplay ${./share/resources/shutter-long.wav}'';
          "${modifier}+Shift+Print" = ''exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp; ${pkgs.alsa-utils}/bin/aplay --quiet ${./share/resources/shutter-short.wav})\" \"''${HOME}/Pictures/screenshot-$(date --iso-8601=seconds).png\"'';
          # audio volume control TODO replace volnoti
          #"XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 -5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsa-utils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          #"XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 +5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsa-utils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          #"XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute 0 toggle; exec ${pkgs.alsa-utils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '\\[off\\]' && ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsa-utils}/bin/amixer -c ${card} -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1) || ${pkgs.volnoti}/bin/volnoti-show -m";
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
          "Shift+XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 100%";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 3%-";
          "Shift+XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 0%";
          # screen capture
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
      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        # needs qt5.qtwayland in systemPackages
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      #systemd.target = "sway-session.target";
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
      profiles.home.outputs = [
        {
          status = "enable";
          criteria = "DP-1";
          mode = "1920x1080";
          position = "0,0";
        }
        {
          status = "enable";
          criteria = "DP-3";
          mode = "1920x1080";
          position = "1920,0";
        }
        {
          status = "enable";
          criteria = "eDP-1";
          mode = "1920x1200";
          position = "960,1080";
        }
      ];
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

    # TODO replace volnoti
    #systemd.user.services.volnoti = {
    #  Unit = {
    #    Description = "Lightweight volume notification daemon";
    #    BindsTo = [ "sway-session.target" ];
    #  };
    #  Service = {
    #    Type = "simple";
    #    ExecStart = "${pkgs.volnoti}/bin/volnoti -n";
    #    RestartSec = 3;
    #    Restart = "always";
    #  };
    #  Install = {
    #    WantedBy = [ "sway-session.target" ];
    #  };
    #};

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
        window.decorations_theme_variant = "dark";
        scrolling.history = 10000;
        font.normal.family = "${font.monospace}";
        font.offset = { x = 0; y = 0; };
        font.glyph_offset = { x = 0; y = 0; };
        #draw_bold_text_with_bright_colors = false;
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
          program = "${pkgs.alsa-utils}/bin/aplay";
          args = [ "--samples=14500" ./share/bell.wav ];
        };
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      history.extended = true;
      oh-my-zsh.enable = true;
      oh-my-zsh.plugins = [
        "vi-mode"
        "z"
        "git"
        "sudo"
        #"adb"
        "per-directory-history"
      ];
      #oh-my-zsh.theme = "phiware";
      #oh-my-zsh.custom = "${./share/oh-my-zsh}";
      shellAliases = {
        nix-shell = ''nix-shell --command "$SHELL"'';
      };
      localVariables = rec {
	      PATH = "$PATH:$HOME/.cargo/bin";
        LOCALE_ARCHIVE = "$HOME/.nix-profile/lib/locale/locale-archive";
        GOPRIVATE = "github.com/au-phiware";
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
      '' +
      #''complete -C '${pkgs.awscli2}/bin/aws_legacy_completer' aws'' +
      ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${./share/p10k.zsh}
      '';
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

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
        goyo-vim
        # TODO: vim-scripts/DrawIt
        # TODO: atimholt/spiffy_foldtext
      ];
      settings = {
        background = "dark";
        directory = [ "$HOME/.vim/swapfiles" ];
        expandtab = true;
      };
      extraConfig = ''
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

        " Silence markdownlint warnings about GHF markdown
        let g:syntastic_quiet_messages = { 'regex': ["No link definition for link ID '[ x]'"] }
      '';
    };

    programs.git = {
      enable = true;
      userEmail = "clawson@transurban.tech";
      userName = "Corin Lawson";
      aliases = {
        amend = "commit --amend --signoff";
        sign = "commit --signoff --gpg-sign";
        fixup = "commit --fixup";
        force-push = "push --force";
        log-all = "log --all --graph --decorate --oneline";
      };
      ignores = [
        "*~"
        "*.sw*"
        # direnv is often a personal choice
        "/.envrc"
        "/.direnv/"
        # For when nix is a personal choice
        "/result"
        "/result-bin"
        "/flake.nix"
        "/flake.lock"
      ];
      extraConfig = {
        core = { excludesfile = "~/.cvsignore"; };
        init = { defaultBranch = "main"; };
        push = { default = "simple"; };
        pull = { rebase = true; };
        commit = {
          template = "${./share/git-commit-template}";
          verbose = true;
        };
        rebase = { interactive = true; };
        branch = { autosetupmerge = true; };
        url = {
          "git@github.com:au-phiware/" = {
            insteadOf = "https://github.com/au-phiware/";
          };
          "git@github.com:transurbantech/" = {
            insteadOf = "https://github.com/transurbantech/";
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
        enable = false;
        options = {
          syntax-theme = "Solarized (dark)";
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
    };

    home.stateVersion = "18.09";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.07"
  ];
  environment = {
    loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty2" ]; then
        exec sway
      fi
    '';

    pathsToLink = [
      "/share/zsh"
      "/share/icons/hicolor"
      "/share/pixmaps"
    ];

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
      git delta
      #gitAndTools.hub
      #mercurial
      jq
      tree
      gnupg
      zip
      unzip
      zstd
      imagemagick
      zlib
      icu
      util-linux
      xdotool
      smartmontools
      cdrtools
      multipath-tools
      inotify-tools
      libnotify
      xdg-desktop-portal-wlr
      lsd

      psmisc
      bind
      tcpdump
      bridge-utils
      inetutils
      openssl
      #libvirt
      #virt-viewer virt-manager
      #qemu-utils qemu_kvm
      #win-virtio #win-qemu
      #spice win-spice
      dnsmasq
      #awscli2
      krb5
      libkrb5
      libsecret
      lttng-ust
      patchelf
      #powershell
      #thefuck
      rlwrap
      bc
      hexedit

      oh-my-zsh
      #python-with-pkgs
      #python38Packages.flake8
      #python38Packages.powerline
      #python38Packages.pylint
      #go
      #gotools
      #gopls
      #grpc
      #(rstudioWrapper.override{ packages = with rPackages; [ devtools remotes dbplyr dplyr RProtoBuf profile ]; })
      #protobuf
      bats
      #rclone
      lm_sensors
      #(vim_configurable.override { python3 = python-with-pkgs; })
      vim
      languagetool
      #proselint
      mdl
      universal-ctags
      gdb
      #gtk-engine-murrine
      #gtk_engines
      #gsettings-desktop-schemas
      #lxappearance
      #numix-solarized-gtk-theme
      #pop-icon-theme
      #nautilus
      gnome-keyring
      xsel
      #lastpass-cli
      shellcheck

      #rustup
      #cargo-fuzz
      #cargo-watch
      #cargo-edit
      #cargo-cross

      alsa-ucm-conf
      alsa-firmware
      alsa-utils
      pavucontrol
      blueman
      mesa-demos
      #freerdp
      #zoom-us
      seahorse

      #surf
      #spotify
      #slack
      firefox
      chromium
      brave
      #vscode
      #unstable.windsurf
      gimp
      #vlc
      #obs-studio
      #sox
      #spectacle
      #inkscape
      #libreoffice
      cabextract
      yq
      qpdf
      qpdfview
      wgetpaste
      feh
      scrot
      #nodejs
      curl
      lshw
      efibootmgr
      #google-drive-ocamlfuse
      #ntfs3g
      lsof
      #compton
      twmn
      #volnoti
      rxvt-unicode
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      global
      discount
      unstable.claude-code
      unstable.opencode
      unstable.copilot
      #unstable.code-cursor

      #unstable.minecraft polymc
      #lunar-client
      prismlauncher jdk25_headless jdk21_headless jdk17_headless 
      #minetest minetestserver
      #airshipper
      #wineWowPackages.waylandFull

      #unstable.android-studio
      #unstable.android-tools

      openscad
      openscad-lsp
      orca-slicer
      #octoprint
      #cura

      ventoy-full
    ];

    sessionVariables = {
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_DBUS_REMOTE" = "1";
    };

    variables = {
      #ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      EDITOR = "vim";
      TMPDIR = "/tmp";
      #DOCKER_MACHINE = "${networking.hostName}";
      #DOCKER_MACHINE_NAME = "${networking.hostName}";
      #DOCKER_HOST = "tcp://${networking.hostName}:2376";
      #DOCKER_TLS_VERIFY = "1";
      #DOCKER_CERT_PATH = "$HOME/.docker";
      # GPG_TTY = "$(tty)";
      XDG_PICTURES_DIR = "$HOME/Pictures";
    };
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts
      terminus_font
      powerline-fonts
      # TODO split into separate packages, e.g.
      #nerd-fonts._0xproto nerd-fonts.droid-sans-mono
      #nerdfonts
      google-fonts
    ];
    fontconfig.defaultFonts.sansSerif = [ "${font.sansSerif}" ];
    fontconfig.defaultFonts.monospace = [ "${font.monospace}" ];
  };

  #programs.java.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.zsh.enable = true;
  programs.bash.completion.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  #programs.adb.enable = true;
  programs.dconf.enable = true;
  programs.steam.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      #extraOptions = "--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/certs/cert.pem --tlskey=/etc/docker/certs/key.pem --host tcp://0.0.0.0:2376";
    };
    #anbox.enable = true;
    libvirtd.enable = false;
  };

  # List services that you want to enable:

  # udev rules to flash librem5
  services.udev.extraRules = ''
    SUBSYSTEM!="usb", GOTO="librem5_devkit_rules_end"
    ATTR{idVendor}=="1fc9", ATTR{idProduct}=="012b", GROUP="plugdev", TAG+="uaccess"
    ATTR{idVendor}=="0525", ATTR{idProduct}=="a4a5", GROUP="plugdev", TAG+="uaccess"
    ATTR{idVendor}=="0525", ATTR{idProduct}=="b4a4", GROUP="plugdev", TAG+="uaccess"
    ATTR{idVendor}=="316d", ATTR{idProduct}=="4c05", GROUP="plugdev", TAG+="uaccess"
    LABEL="librem5_devkit_rules_end"
  '';

  # Enable Bluetooth
  services.blueman.enable = true;

  # Enable Thunderbolt security levels
  services.hardware.bolt.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "18.09"; # Did you read the comment?
  #system.autoUpgrade.enable = true;
}
