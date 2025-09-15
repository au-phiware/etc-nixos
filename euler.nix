# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  config,
  lib,
  pkgs,
  stable,
  unstable,
  ...
}: let
  background = ./share/background.png;
  font = {
    monospace = "MonaspaceNeon";
    sansSerif = "Noto Sans";
    grub = "${pkgs.powerline-fonts}/share/fonts/truetype/Cousine for Powerline.ttf";
    console = "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz";
  };
  theme = {
    bg = "001619";
    base03 = "002b36";
    base02 = "073642";
    base01 = "586e75";
    base00 = "657b83";
    base0 = "839496";
    base1 = "93a1a1";
    base2 = "eee8d5";
    base3 = "fdf6e3";
    yellow = "b58900";
    orange = "cb4b16";
    red = "dc322f";
    magenta = "d33682";
    violet = "6c71c4";
    blue = "268bd2";
    cyan = "2aa198";
    green = "859900";
  };
  python-with-pkgs = with pkgs;
    python310.withPackages (pypkgs:
      with pypkgs; [
        flake8
        msgpack
        powerline
        pynvim
        pylint
      ]);
in rec {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Include Versent's SOC2 requirements
    ./modules/soc2/default.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.font = "${font.grub}";
  boot.loader.grub.backgroundColor = "#${theme.base03}";
  boot.initrd.kernelModules = ["i915" "v4l2loopback"];
  #boot.kernelPackages = unstable.linuxPackages_5_10;
  #boot.kernelPackages = pkgs.linuxPackages_5_9;
  #boot.extraModulePackages = with config.boot.kernelPackages; [ akvcam ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelParams = [
    "snd-intel-dspcfg.dsp_driver=1" # "snd_hda_intel.dmic_detect=0" # Enable sound
    "net.ifnames=0" # Allow wifi interface names longer than 15 chars
    #"hugepages=4096" # Good IF you need it
    "vconsole.keymap=us"
    #"vconsole.font=ter-powerline-v24n"
    # Solarized (dark) colours at boot
    "vt.default_red=0x07,0xdc,0x85,0xb5,0x26,0xd3,0x2a,0xee,0x00,0xcb,0x58,0x65,0x83,0x6c,0x93,0xfd"
    "vt.default_grn=0x36,0x32,0x99,0x89,0x8b,0x36,0xa1,0xe8,0x2b,0x4b,0x6e,0x7b,0x94,0x71,0xa1,0xf6"
    "vt.default_blu=0x42,0x2f,0x00,0x00,0xd2,0x82,0x98,0xd5,0x36,0x16,0x75,0x83,0x96,0xc4,0xa1,0xe3"

    # Graphics settings
    "i915.modeset=1"
    "i915.fastboot=0"       # Disable fastboot for more thorough display initialization
    "i915.enable_guc=3"     # Enable GuC firmware for better scheduling
    "i915.guc_log_level=0"  # Disable GuC logging to reduce overhead
    "i915.enable_fbc=0"     # Disable Frame Buffer Compression
    "i915.enable_psr=0"     # Disable Panel Self Refresh
    "i915.force_probe=*"    # Force probe display outputs
    "i915.reset=1"          # Enable GPU reset if it hangs
    "i915.enable_dc=2"      # Power-saving features
    #"intel_iommu=on" # Allow graphics passthru to VMs
    "i915.max_vfs=0"        # Disable virtual functions since not using GPU passthrough
    "i915.reset=1"          # Enable GPU reset capability

    # Memory management
    "zfs.zfs_arc_max=0x180000000"  # Limit ZFS ARC to 6GB, good for desktop workloads
    "memhp_default_state=online"   # Better memory hotplug handling
    "page_alloc.shuffle=1"         # Reduce memory fragmentation
  ];
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1
    options kvm-intel nested=1
    options kvm-intel ept=1
    options kvm-intel enable_shadow_vmcs=1
    options kvm-intel enable_apicv=1
  '';
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.requestEncryptionCredentials = true;
  boot.blacklistedKernelModules = [
    "snd-soc-dmic"
  ];
  boot.kernel.sysctl = {
    # Memory management
    "vm.swappiness" = 10;                 # Lower value means swap less aggressively, can improve interactive performance
    "vm.vfs_cache_pressure" = 80;         # Reduce file cache pressure
    "vm.watermark_boost_factor" = 15000;  # Earlier memory reclaim
    "vm.watermark_scale_factor" = 200;    # More aggressive memory reclaim
    "vm.page-cluster" = 0;                # Smaller swap chunks

    # I/O management
    "vm.dirty_ratio" = 10;                # Start writeout earlier
    "vm.dirty_background_ratio" = 5;      # Lower value means writeback sooner

    # Process management
    "kernel.sched_autogroup_enabled" = 0; # Better desktop responsiveness
  };

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
  networking.extraHosts = ''
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
  i18n.supportedLocales = ["en_AU.UTF-8/UTF-8" "en_US.UTF-8/UTF-8"];
  console = {
    # font = "Lat2-Terminus16";
    font = "${font.console}";
    #font = "ter-powerline-v24n";
    keyMap = "us";
  };

  # Enable niri window manager.
  programs.niri.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "corin";
  };
  services.xserver.enable = true;
  services.xserver.wacom.enable = true;

  # TODO: Configure Stylix for system-wide theming once compatibility is resolved
  # stylix = {
  #   enable = true;
  #   base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";
  #   image = background;
  #   polarity = "dark";
  #   fonts = {
  #     sansSerif = {
  #       package = pkgs.noto-fonts;
  #       name = font.sansSerif;
  #     };
  #     monospace = {
  #       package = (pkgs.callPackage ./pkgs/monaspace {});
  #       name = font.monospace;
  #     };
  #   };
  # };
  services.xserver.displayManager.lightdm = {
    inherit background;
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
        error-color = "#${theme.red}"
        background-color = "#${theme.base03}"
        background = "${background}"
        window-color = "#${theme.base03}"
        border-color = "#${theme.base03}"
        border-width = 0px
        layout-space = 1
        password-color = "#${theme.base03}"
        password-background-color = "#${theme.base3}"
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
        propagatedBuildInputs = [super.wl-clipboard];
        makeFlags = ["PREFIX=$(out)"];
      };

      xsel = self.wl-clipboard-x11;
      xclip = self.wl-clipboard-x11;
    })

    #(self: super: {
    #  aider-chat = super.buildFHSEnv {
    #    name = "aider";
    #    targetPkgs = pkgs: with unstable; [
    #      aider-chat.withPlaywright
    #      python311
    #      python311.pkgs.pip
    #      python311.pkgs.setuptools
    #      python311.pkgs.wheel
    #      gcc
    #      binutils
    #      stdenv.cc.cc.lib
    #    ];
    #    #extraBuildCommands = ''
    #    #  mkdir -p usr/local/aider-venv
    #    #'';
    #    runScript = pkgs.writeScript "aider-wrapper" ''
    #      #!${pkgs.bash}/bin/bash

    #      ## Use user-writeable location
    #      #VENV_DIR="$HOME/.local/share/aider/venv"
    #      #mkdir -p "$(dirname "$VENV_DIR")"

    #      ## Activate the pre-built venv
    #      #if [ ! -d "$VENV_DIR" ]; then
    #      #  python3.11 -m venv "$VENV_DIR"
    #      #  source "$VENV_DIR/bin/activate"
    #      #  pip install --upgrade pip setuptools wheel
    #      #  python3.11 -m pip install --upgrade --upgrade-strategy only-if-needed 'aider-chat[help]' --extra-index-url https://download.pytorch.org/whl/cpu
    #      #else
    #      #  source "$VENV_DIR/bin/activate"
    #      #fi

    #      if [ -z "$ANTHROPIC_API_KEY" ]; then
    #        export ANTHROPIC_API_KEY=$(${pkgs.libsecret}/bin/secret-tool lookup anthropic-api-key aider 2>/dev/null || true)
    #      fi

    #      exec aider "$@"
    #    '';
    #    meta = unstable.aider-chat.meta;
    #  };
    #})
  ];

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.fwupd.enable = true;

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
  # Interferes with cloudfare-warp
  #services.resolved.enable = true;

  #services.flatpak.enable = true;

  # OpenVPN
  services.openvpn.servers = {
    euc = {
      autoStart = false;
      #TODO authUserPass = { username = "corin.lawson"; password = "..."; };
      config = ''config /etc/openvpn/client/euc.conf '';
    };
  };

  # Enable lorri
  services.lorri.enable = true;

  services.sshd.enable = true;
  hardware.uinput.enable = true;

  # Enable creativecreature pulse tool
  #services.pulse.enable = false;

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
    #configFile = '' %users ALL=(ALL) NOPASSWD:${pkgs.physlock}/bin/physlock -l,NOPASSWD:${pkgs.physlock}/bin/physlock -L '';
    extraRules = [
      {
        groups = [ "users" ];
        commands = [
          {
            command = "${pkgs.physlock}/bin/physlock -l";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.physlock}/bin/physlock -L";
            options = [ "NOPASSWD" ];
          }
        ];
      }
      {
        groups = [ "sst" ];
        commands = [
          {
            command = "/opt/sst/tunnel tunnel start *";
            options = [ "NOPASSWD" "SETENV" ];
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

  services.actkbd = {
    enable = true;
    bindings = [
      # Mute
      {
        keys = [ 113 ];
        events = [ "key" ];
        command = "${pkgs.pulseaudio}/bin/pactl set-sink-mute 0 toggle";
      }
      # Volume down
      {
        keys = [ 114 ];
        events = [ "key" "rep" ];
        command = "${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 -5%";
      }
      # Volume up
      {
        keys = [ 115 ];
        events = [ "key" "rep" ];
        command = "${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 +5%";
      }
    ];
  };
  programs.light = {
    enable = true;
    brightnessKeys.enable = true;
  };

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
      "disk"
      "docker"
      "kvm"
      "libvirt"
      "libvirtd"
      "media"
      "networkmanager"
      "plugdev"
      "pulse"
      "sst"
      "systemd-journal"
      "uinput"
      "usb"
      "video"
      "wheel"
    ];
  };
  users.groups.corin.gid = 1000;
  users.groups.sst = {};
  home-manager.users.corin = let
    lock = with pkgs;
      writeShellScriptBin "lock.sh" ''
        set -ue

        screen=$(${coreutils}/bin/mktemp -p /tmp lockscreen-XXXX)
        #trap "sudo ${physlock}/bin/physlock -L; ${coreutils}/bin/rm '$screen'*" EXIT
        trap "${coreutils}/bin/rm '$screen'*" EXIT

        outputs=$(
          (
            ${pkgs.niri}/bin/niri msg --json outputs \
              | ${jq}/bin/jq --raw-output '
                .[]
                | "${grim}/bin/grim -t jpeg -q 10 -g \"\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)\" - | ${imagemagick}/bin/convert -sample \"\(.rect.width / 8)x\(.rect.height / 8)\" -modulate 100,70 - -sample \"\(.rect.width)x\(.rect.height)\" \"${./share/resources/shield.png}\" -geometry +\(.rect.width / 2 - 148)+\(.rect.height / 2 - 149) -composite '$screen'-\(.name).png & echo \"\(.name)\""';
            echo wait;
          ) | ${bash}/bin/bash
        )
        #sudo ${physlock}/bin/physlock -l
        for o in $outputs; do echo '--image '"$o:$screen-$o.png"; done | \
          ${findutils}/bin/xargs ${swaylock}/bin/swaylock \
            --ignore-empty-password \
            --show-failed-attempts \
            --color 000000 \
            --indicator-radius 164 \
            --indicator-thickness 30 \
            --font "${font.sansSerif}" \
            --font-size 20 \
            --ring-color '#${theme.green}' \
            --line-color '000000CC' \
            --text-color '#${theme.green}' \
            --inside-color '#${theme.green}66' \
            --key-hl-color '#${theme.blue}' \
            --bs-hl-color '#${theme.red}' \
            --separator-color '000000CC' \
            --ring-clear-color '#${theme.red}' \
            --line-clear-color '000000CC' \
            --text-clear-color '#${theme.red}' \
            --inside-clear-color '#${theme.red}66' \
            --ring-caps-lock-color '#${theme.yellow}' \
            --line-caps-lock-color '000000CC' \
            --text-caps-lock-color '#${theme.yellow}' \
            --inside-caps-lock-color '#${theme.yellow}66' \
            --caps-lock-key-hl-color '#${theme.blue}' \
            --caps-lock-bs-hl-color '#${theme.red}' \
            --ring-ver-color '#${theme.blue}' \
            --line-ver-color '000000CC' \
            --text-ver-color '#${theme.blue}' \
            --inside-ver-color '#${theme.blue}66' \
            --ring-wrong-color '#${theme.red}' \
            --line-wrong-color '000000CC' \
            --text-wrong-color '#${theme.red}' \
            --inside-wrong-color '#${theme.red}66'
      '';
  in
    {
      config,
      pkgs,
      ...
    }: {
      home.stateVersion = "18.09";

      home.packages = with pkgs; [
        swaylock
        swayidle
        wl-clipboard
        xwayland # for legacy apps
        xwayland-satellite # better xwayland integration for niri
        mako # notification daemon
        foot # kitty # the default terminal in the config
        wofi # Dmenu replacement
        wdisplays # xrandr replacement
        kanshi # autorandr replacement
        eww # status bar replacement
        ksnip # flameshot # grim # scrot replacement
      ];
      programs.niri = {
        settings = {
          input = {
            keyboard.xkb = {
              layout = "us";
            };
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
          };

          layout = {
            gaps = 16;
          };

          prefer-no-csd = true;

          animations = {
            slowdown = 2.0;
          };

          binds = with config.lib.niri.actions; {
            "Mod+Shift+Return".action = spawn "${pkgs.foot}/bin/foot";
            "Mod+p".action = spawn "${pkgs.wofi}/bin/wofi" "--show" "run";
            "Mod+Shift+c".action = close-window;
            "Mod+Left".action = focus-column-left;
            "Mod+Right".action = focus-column-right;
            "Mod+h".action = focus-column-left;
            "Mod+l".action = focus-column-right;
            "Mod+f".action = fullscreen-window;
            "Mod+Shift+e".action = quit;
            "Print".action = spawn "${pkgs.ksnip}/bin/ksnip" "--portal";
          };

          spawn-at-startup = [
            { command = ["${pkgs.foot}/bin/foot"]; }
          ];
        };
      };

      # TODO: Configure Anyrun once overlay issues are resolved
      # For now, we'll use wofi as a fallback launcher

      #home.file = {
      #  ".config/xdg-desktop-portal-wlr/config".text = ''
      #    [screencast]
      #    output=
      #    chooser_cmd=${pkgs.wofi}/bin/wofi -d -n --prompt 'Select screen to output'
      #    chooser_type=dmenu
      #  '';
      #};

      home.file.".local/bin/drm-monitor-shared.sh" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash

          # Shared state file
          STATE_FILE="/tmp/drm-errors-state"

          # Function to read current state
          get_state() {
            if [ -f "$STATE_FILE" ]; then
              cat "$STATE_FILE"
            else
              echo "0 $(${pkgs.coreutils}/bin/date +%s)"
            fi
          }

          # Function to update state
          update_state() {
            echo "$1 $2" > "$STATE_FILE"
          }

          # Function to calculate errors in window
          get_errors_in_window() {
            read count timestamp < <(get_state)
            current_time=$(${pkgs.coreutils}/bin/date +%s)
            window_size=300  # 5 minutes

            if [ $((current_time - timestamp)) -gt $window_size ]; then
              update_state 0 $current_time
              echo 0
            else
              echo "$count"
            fi
          }
        '';
      };
      systemd.user.services.monitor-drm-errors = {
        Unit = {
          Description = "Monitor DRM atomic commit failures";
          After = "graphical-session.target";
          PartOf = "graphical-session.target";
        };
        Service = {
          ExecStart = let
            script = pkgs.writeShellScript "monitor-drm-errors" ''
              source ~/.local/bin/drm-monitor-shared.sh

              # Monitor journal for atomic commit failures
              ${pkgs.systemd}/bin/journalctl -f -n 0 | while read -r line; do
                if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "connector.*Atomic commit failed: Device or resource busy"; then
                  read count timestamp < <(get_state)
                  current_time=$(${pkgs.coreutils}/bin/date +%s)

                  # Reset counter if window has elapsed
                  if [ $((current_time - timestamp)) -gt 300 ]; then
                    count=1
                    timestamp=$current_time
                  else
                    count=$((count + 1))
                  fi

                  update_state $count $timestamp

                  # Print status
                  echo "$(${pkgs.coreutils}/bin/date): $count failures in current window"

                  # Notify if threshold exceeded
                  if [ $count -gt 50 ]; then
                    ${pkgs.libnotify}/bin/notify-send -u critical \
                      "Display Issues Detected" \
                      "High frequency of atomic commit failures ($count in last 5m)"
                  fi
                fi
              done
            '';
          in "${script}";

          Restart = "always";
          RestartSec = "30s";
          Nice = 10;
          IOSchedulingClass = "idle";
          MemoryMax = "50M";
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
      home.file.".local/bin/waybar-drm-status.sh" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash

          source ~/.local/bin/drm-monitor-shared.sh

          while true; do
            count=$(get_errors_in_window)

            if [ "$count" -gt 0 ]; then
              class="warning"
              [ "$count" -gt 50 ] && class="critical"

              echo "{\"text\": \"🎮 $count\", \"class\": \"$class\", \"tooltip\": \"$count DRM errors in last 5m\"}"
            else
              echo "{\"text\": \"\", \"class\": \"normal\"}"
            fi

            sleep 5
          done
        '';
      };

      # TODO: Replace with eww configuration for status bar
      # For now, niri doesn't need waybar - it uses its own workspace management
      programs.vscode = {
        enable = true;
        profiles.default.extensions = with pkgs.vscode-extensions; [
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
        settings = [
          {
            profile.name = "okx-hub";
            profile.outputs = [
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
          }
          {
            profile.name = "dell-hub";
            profile.outputs = [
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
          }
        ];
      };

     #systemd.user.services.sunshine = {
     #  Unit = {
     #    Description = "Sunshine self-hosted game stream host for Moonlight.";
     #    StartLimitIntervalSec = "500";
     #    StartLimitBurst = "5";
     #  };

     #  Service = {
     #    ExecStart = "${pkgs.sunshine}/bin/sunshine";
     #    Environment = "PATH=${
     #      lib.makeBinPath (with pkgs; [
     #        coreutils
     #        findutils
     #        gnugrep
     #        gnused
     #        xorg.xrandr
     #        util-linux
     #        pulseaudio
     #        steam
     #        prismlauncher
     #      ])
     #    }";
     #    Restart = "on-failure";
     #    RestartSec = "5s";
     #  };

     #  Install = {WantedBy = ["xdg-desktop-autostart.target"];};
     #};

      systemd.user.services.polkit-gnome-authentication-agent-1 = {
        Unit = {
          Description = "polkit-gnome-authentication-agent-1";
          BindsTo = ["niri.service"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
        Install = {
          WantedBy = ["niri.service"];
        };
      };

      systemd.user.services.swayidle = {
        Unit = {
          Description = "Idle manager for Wayland";
          BindsTo = ["niri.service"];
        };
        Service = let
          swayidleStart = pkgs.writeShellScript "swayidle-start.sh" ''
            ${pkgs.swayidle}/bin/swayidle \
              timeout  300 '${pkgs.brightnessctl}/bin/brightnessctl --save set 10%' \
                    resume '${pkgs.brightnessctl}/bin/brightnessctl --restore' \
              timeout  600 ${lock}/bin/lock.sh \
              timeout 1200 '${pkgs.niri}/bin/niri msg action power-off-monitors' \
                    resume '${pkgs.niri}/bin/niri msg action power-on-monitors' \
              timeout 1800 '${pkgs.niri}/bin/niri msg action power-on-monitors; \
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
          WantedBy = ["niri.service"];
        };
      };

      #systemd.user.services.volnoti = {
      #  Unit = {
      #    Description = "Lightweight volume notification daemon";
      #    BindsTo = ["sway-session.target"];
      #  };
      #  Service = {
      #    Type = "simple";
      #    ExecStart = "${pkgs.volnoti}/bin/volnoti -n";
      #    RestartSec = 3;
      #    Restart = "always";
      #  };
      #  Install = {
      #    WantedBy = ["sway-session.target"];
      #  };
      #};

      services.mako = {
        enable = true;
        settings = {
          icon-path = "/run/current-system/sw/share/icons/hicolor:/run/current-system/sw/share/pixmaps";
          text-color = "#${theme.base02}ff";
          background-color = "#${theme.base3}ff";
          progress-color = "over #${theme.base1}66";
          border-color = "#${theme.base2}ff";
          border-radius = 6;
          border-size = 4;
          padding = "10";
          margin = "14";
          font = "${font.sansSerif} 14";
        };
      };

      xresources.extraConfig = builtins.readFile (
        pkgs.fetchFromGitHub {
          owner = "solarized";
          repo = "xresources";
          rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
          sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
        }
        + "/Xresources.dark"
      );

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-backgroundremoval
        ];
      };

      programs.foot = {
        enable = true;
        settings = {
          main = {
            term = "xterm-256color";

            font = "${font.monospace}:size=10";
            dpi-aware = "yes";
            pad = "2x2";
            initial-window-mode = "maximized";
          };

          cursor.color = "${theme.base03} ${theme.base1}";
          colors = with theme; {
            background = "${base03}";
            foreground = "${base0}";
            regular0   = "${base02}";
            regular1   = "${red}";
            regular2   = "${green}";
            regular3   = "${yellow}";
            regular4   = "${blue}";
            regular5   = "${magenta}";
            regular6   = "${cyan}";
            regular7   = "${base2}";
            bright0    = "${base03}";
            bright1    = "${orange}";
            bright2    = "${base01}";
            bright3    = "${base00}";
            bright4    = "${base0}";
            bright5    = "${violet}";
            bright6    = "${base1}";
            bright7    = "${base3}";
          };
          scrollback.lines = 10000;

          mouse = {
            hide-when-typing = "yes";
          };
        };
      };

      programs.kitty = {
        font.name = "${font.monospace}";
        settings = {
          # Set the initial window size (in cells)
          initial_window_width = 80;
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
          background = "#${theme.bg}";
          foreground = "#${theme.base0}";
          cursor = "#${theme.base3}";
          cursor_text_color = "#000000";

          # Define color palette
          color0 = "#${theme.base03}";
          color1 = "#${theme.red}";
          color2 = "#${theme.green}";
          color3 = "#${theme.yellow}";
          color4 = "#${theme.blue}";
          color5 = "#${theme.magenta}";
          color6 = "#${theme.cyan}";
          color7 = "#${theme.base2}";
          color8 = "#${theme.base03}";
          color9 = "#${theme.orange}";
          color10 = "#${theme.base01}";
          color11 = "#${theme.base00}";
          color12 = "#${theme.base0}";
          color13 = "#${theme.violet}";
          color14 = "#${theme.base1}";
          color15 = "#${theme.base3}";

          # Kitty does not support bell animations, but it does support changing the bell color
          # and running a command when the bell rings
          bell_border_color = "#${theme.base3}";
          enable_audio_bell = false;
          command_on_bell = "${pkgs.alsa-utils}/bin/aplay --samples=14500 ${./share/bell.wav}";
        };
      };

      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = ["--cmd cd"];
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
        oh-my-zsh.plugins = ["vi-mode" "git" "sudo" "per-directory-history"];
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
          DIRENV_LOG_FORMAT = "";
        };
        initContent = with pkgs.lib; (mkMerge [
          (mkBefore ''
            # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
            # Initialization code that may require console input (password prompts, [y/n]
            # confirmations, etc.) must go above this block; everything else may go below.
            if [[ -r "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh" ]]; then
              source "$\{XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$\{(%):-%n}.zsh"
            fi
          '')
          ''
            [[ "$TERM" == "linux" ]] && setfont "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz"

            complete -C '${pkgs.awscli2}/bin/aws_legacy_completer' aws

            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            source ${./share/p10k.zsh}
          ''
        ]);
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
          goyo-vim
          limelight-vim
          orgmode
          LanguageTool-nvim
          vim-wordy
          # TODO: vim-scripts/DrawIt
          # TODO: atimholt/spiffy_foldtext
          wgsl-vim
        ];
        settings = {
          background = "dark";
          directory = ["$HOME/.vim/swapfiles"];
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
          package = pkgs.vimPlugins.coc-nvim;
          settings = {
            "coc.preferences.watchmanPath" = "${pkgs.watchman}/bin/watchman";
          };
        };

        plugins = let
          # omnisharp-vim = pkgs.vimUtils.buildVimPlugin {
          #   name = "omnisharp-vim";
          #   src = pkgs.fetchFromGitHub {
          #     owner = "OmniSharp";
          #     repo = "omnisharp-vim";
          #     rev = "f9c5d3e3375e8b5688a4506e813cb21bdc7329b1";
          #     hash = "sha256-z3Dgrm9pNWkvfShPmB9O8TqpY592sk1W722zduOSing=";
          #   };
          # };
          # omnisharp-extraConfig = ''
          #   " OmniSharp (language server)
          #   let g:OmniSharp_server_path = '${unstable.omnisharp-roslyn}/bin/OmniSharp'
          #   let g:OmniSharp_log_dir = '${config.home.homeDirectory}/.local/share/omnisharp-vim/log'
          #   let g:ale_fixers = { 'cs': ['remove_trailing_lines', 'trim_whitespace', 'dotnet-format']}
          #   let g:ale_fix_on_save = 1
          #   autocmd FileType cs nmap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)
          #   autocmd FileType cs nmap <silent> <buffer> gr <Plug>(omnisharp_find_usages)
          #   autocmd FileType cs nmap <silent> <buffer> gi <Plug>(omnisharp_find_implementations)
          #   autocmd FileType cs nmap <silent> <buffer> gy <Plug>(omnisharp_go_to_type_definition)
          #   autocmd FileType cs nmap <silent> <buffer> <Leader>os= <Plug>(omnisharp_code_format)
          #   augroup FormatAutogroup
          #     autocmd!
          #     autocmd BufWritePre *.cs :OmniSharpCodeFormat
          #   augroup END
          # '';
        in
          with pkgs.vimPlugins; [
            vim-surround
            vim-repeat
            vim-fugitive
            vim-sleuth
            vim-speeddating
            vim-commentary
            vim-vinegar
            emmet-vim
            nightfly
            vim-airline
            vim-airline-themes
            # vim-dispatch
            # tagbar
            goyo-vim
            limelight-vim
            # orgmode
            LanguageTool-nvim
            vim-wordy
            vim-emoji
            venn-nvim
            nvim-treesitter
            #unstable.vimPlugins.neorg
            #pkgs.vimPlugins.nvim-treesitter-parsers.norg
            markdown-preview-nvim

            vim-nix
            vim-startify
            vim-go
            typescript-vim
            #typescript-tools-nvim
            #omnisharp-vim
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

            nvim-dap
            nvim-dap-ui
            nvim-dap-go

            #pulseVimPlugin

            # AI code-completion
            copilot-lua
            CopilotChat-nvim
            #unstable.vimPlugins.codeium-vim
          ];
        extraConfig = ''
          let mapleader=" "
          "set termencoding=utf-8 encoding=utf-8
          filetype plugin indent on
          "syntax enable

          " Solarized theme configuration
          set termguicolors
          colorscheme nightfly
          set background=dark

          " Airline configuration
          let g:airline_theme='solarized'
          let g:airline_solarized_bg='dark'
          let g:airline_powerline_fonts = 1

          "set t_Co=256
          "nmap <F8> :TagbarToggle<CR>

          " Text width
          set colorcolumn=+1

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
        ''; #++ omnisharp-extraConfig;
        extraLuaConfig = ''
          -- require("neorg").setup {
          --   load = {
          --     ["core.defaults"] = {},
          --     ["core.dirman"] = {
          --       config = {
          --         workspaces = {
          --           notes = "~/Documents/notes",
          --           journal = "~/Documents/journal",
          --           blogs = "~/Documents/blogs",
          --         },
          --       },
          --     },
          --     ["core.journal"] = {
          --       config = {
          --         journal_folder = "",
          --         workspace = "journal",
          --       },
          --     },
          --     ["core.concealer"] = {
          --       config = {
          --         icons = {
          --           todo = {
          --             undone = {
          --               icon = " ",
          --             },
          --             recurring = {
          --               icon = "󰃮",
          --             },
          --             cancelled = {
          --               icon = "󰩺",
          --             },
          --             pending = {
          --               icon = "󰔟",
          --             },
          --             on_hold = {
          --               icon = "󰏤",
          --             },
          --             uncertain = {
          --               icon = "?",
          --             },
          --             urgent = {
          --               icon = "!",
          --             },
          --           },
          --         },
          --       },
          --     },
          --   },
          -- }

          require("copilot").setup({
            suggestion = {
              enabled = true,
              auto_trigger = true,
              keymap = {
                accept = "<Tab>",
              },
            },
            filetypes = {
              yaml = true,
              markdown = true,
              gitcommit = true,
            },
          })
          require("CopilotChat").setup({
            mappings = {
              submit_prompt = {
                normal = "CR",
                insert = "<C-CR>"
              },
            },
          })

          -- Copilot Logger
          local function setup_copilot_logger()
            local copilot_api = require("copilot.api")
            local original_notify_accepted = copilot_api.notify_accepted

            copilot_api.notify_accepted = function(client, params, callback)
              -- Log the function call
              vim.fn.PulseLogFunctionCall('copilot.api.notify_accepted')

              -- Call the original function
              return original_notify_accepted(client, params, callback)
            end
          end

          -- Defer the setup to ensure Copilot is loaded
          vim.defer_fn(setup_copilot_logger, 100)
        '';
      };

      home.file.".cvsignore".source = ./cvsignore;
      home.file.".local/share/gitconfig/hooks/prepare-commit-msg" = {
        executable = true;
        source = "${(pkgs.callPackage ./git-hooks/prepare-commit-msg {})}/bin/prepare-commit-msg";
      };

      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = "Corin Lawson";
            email = "corin@phiware.com.au";
          };
          template-aliases = {
            default_commit_description = ''
              "JJ: If applied, this commit will...

              JJ: Why is this change needed?
              Prior to this change,

              JJ: How does it address the issue?
              This change

              JJ: Provide links to any relevant tickets, articles or other resources
              "
            '';
          };
          ui = {
            default-command = ["status"];
            bookmark-list-sort-keys = ["committer-date-"];
            pager = ":builtin";
            streampager.interface = "quit-if-one-page";
          };
        };
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
          force-push = "push --force-with-lease";
          log-all = "log --all --graph --decorate --oneline";
        };
        extraConfig = {
          core = {
            excludesfile = "${./cvsignore}";
            hooksPath = "${config.home.homeDirectory}/.local/share/gitconfig/hooks";
          };
          init = {defaultBranch = "main";};
          push = {default = "current";};
          pull = {rebase = true;};
          merge = {conflictStyle = "zdiff3";};
          diff = {algorithm = "histogram";};
          commit = {
            template = "${./share/gitconfig/commit-template}";
            verbose = true;
          };
          rebase = {updateRefs = true;};
          rerere = {enabled = true;};
          branch = {autosetupmerge = true;};
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
            theme = "ansi";
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
          proxyCommand = "${(pkgs.callPackage ./pkgs/aws-ssm-ssh-proxycommand {})}/aws-ssm-ssh-proxycommand.sh %h %r %p";
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
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #  "cloudflare-warp"
  #  "falcon-sensor"
  #  "vscode"
  #  "vscode-extension-ms-vsliveshare-vsliveshare"
  #  "vscode-extension-github-copilot"
    "steam" "steam-unwrapped"
  #  "1password" "1password-cli"
  #  "displaylink"
  #  "zoom"
  #  "aspell-dict-en-science"
  #  "claude-desktop"
  ];
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
      "wireplumber/policy.lua.d/51-bluetooth-policy.lua".text = ''
        rule = {
          matches = {
            {
              { "node.name", "matches", "bluez_output.*" },
            },
          },
          apply_properties = {
            ["node.nick"] = "Bluetooth",
            ["priority.driver"] = 1100,
            ["priority.session"] = 1100,
          },
        }
        table.insert(bluez_monitor.rules, rule)
      '';
    };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      displaylink
      thunderbolt
      bolt
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
      git
      gitAndTools.delta
      mercurial
      jq
      jnv
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
      spice
      win-spice
      docker-compose
      ansible
      #unstable.awscli2
      awscli2
      ssm-session-manager-plugin
      saml2aws
      krb5
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

      nushell
      z-lua
      oh-my-zsh
      uv # Python package and project manager
      #python-with-pkgs
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
      #(maven.override {
      #  jdk = jdk8;
      #})
      #(go_1_13.overrideAttrs (oldAttrs: rec {
      #  name = "go-${version}";
      #  version = "1.13.4";
      #  src = fetchurl {
      #    url = "https://dl.google.com/go/go${version}.src.tar.gz";
      #    sha256 = "093n5v0bipaan0qqc02wash18r625y74r4zhmjwlc9zf8asfmnwm";
      #  };
      #}))
      go
      gotools
      gopls
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
      nautilus
      gnome-keyring
      xsel
      gitAndTools.hub
      gh
      lastpass-cli
      shellcheck
      watchman
      alejandra
      atac

      arandr
      alsa-ucm-conf
      alsa-firmware
      alsa-utils
      pavucontrol
      glxinfo
      freerdp
      zoom-us
      seahorse
      plantuml-c4

      surf
      #spotify
      #unstable.teams
      firefox
      chromium
      brave
      #unstable.microsoft-edge-beta
      gimp
      vlc
      sox
      #kdePackages.spectacle
      inkscape
      libreoffice
      pdftk
      cabextract
      yq
      qpdf
      libsForQt5.okular
      qpdfview
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
      #volnoti
      rxvt-unicode
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      global
      discount
      #jetbrains.idea-community
      rnnoise-plugin
      #webcamoid
      xournalpp
      #unstable.code-cursor
      zed-editor
      #aider-chat
      yazi
      #claude-desktop-unfree
      #inputs.claude-desktop.packages.${pkgs.system}.claude-desktop
      unstable.claude-code

      slack
      slack-cli
      #(callPackage ./pkgs/slack {})
      #(callPackage ./pkgs/pact { })

      prismlauncher
      #airshipper
      wineWowPackages.waylandFull
      #sunshine

      #unstable.dotnet-sdk_8
      #unstable.dotnet-runtime_8
      #unstable.csharprepl
      #azure-functions-core-tools
      #(callPackage ./pkgs/azure-functions-core-tools { })
      #unstable.azure-cli
      #terraform

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
      #typodermic-free-fonts
      typodermic-public-domain
      open-sans
      google-fonts
      open-fonts
      terminus_font
      powerline-fonts
      google-fonts
      (callPackage ./pkgs/monaspace {})
      noto-fonts
      noto-fonts-emoji
    ];
    fontconfig.defaultFonts.sansSerif = ["${font.sansSerif}"];
    fontconfig.defaultFonts.monospace = ["${font.monospace}"];
  };

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
    #22
    #80
    #443
    #14004
    #14005
    #25565
    # sunshine ports
    #47984
    #47989
    #47990
    #48010
  ];
  networking.firewall.allowedUDPPorts = [
    # sunshine ports
    #47998
    #47999
    #48000
    #48002
    # Allow mDNS for local peer discovery
    5353
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
  system.autoUpgrade = {
    enable = true;
    dates = "17:30";
    flake = inputs.self.outPath;
    flags = ["--update-input" "nixpkgs-stable" "--update-input" "home-manager-stable" "--commit-lock-file"];
  };
  systemd.services.nixos-upgrade.serviceConfig.Nice = 19;
  systemd.services.nixos-upgrade.serviceConfig.IOSchedulingClass = "idle";
  systemd.services.nixos-upgrade.serviceConfig.IOSchedulingPriority = 7;
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";
  nix.daemonIOSchedPriority = 7;
}
