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
    blue    = "#268db2";
    cyan    = "#2aa198";
    green   = "#859900";
  };
  python-with-pkgs = with pkgs; python38.withPackages (pypkgs: with pypkgs; [
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
      <home-manager/nixos>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.font = "${pkgs.powerline-fonts}/share/fonts/truetype/${font.monospace}.ttf";
  boot.loader.grub.backgroundColor = "${theme.base03}";
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelPackages = unstable.linuxPackages_5_10;
  #boot.kernelPackages = pkgs.linuxPackages_5_9;
  boot.kernelParams = [
    "snd-intel-dspcfg.dsp_driver=1" # "snd_hda_intel.dmic_detect=0" # Enable sound
    "net.ifnames=0" # Allow wifi interface names longer than 15 chars
    #"intel_iommu=on" # Allow graphics passthru to VMs
    "i915.enable_fbc=1"
    "i915.enable_psr=2"
    "hugepages=4096"
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

  powerManagement.cpuFreqGovernor = "performance";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  #networking.dhcpcd.wait = "background";
  networking.interfaces.wlp0s20f3.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.supportedLocales = [ "en_AU.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  console = {
    # font = "Lat2-Terminus16";
    #font = "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz";
    keyMap = "us";
  };

  # Enable a Desktop Environment.
  services.xserver.enable = true;
  services.xserver.autorun = true;
  services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.defaultSession = "none+i3";
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
        error-color = "#dc322f"
        background-color = "#002b36"
        background = "${./share/background.png}"
        window-color = "#002b36"
        border-color = "#002b36"
        border-width = 0px
        layout-space = 1
        password-color = "#002b36"
        password-background-color = "#fdf6e3"
      '';
    };
  };
  services.xserver.desktopManager.gnome3.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  nixpkgs.config.pulseaudio = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput = {
    enable = true;
    naturalScrolling = true;
  };

  # Enable resolved (needed by OpenVPN)
  services.resolved.enable = true;

  # OpenVPN
  services.openvpn.servers = let
    clientConfig = pkgs.writeTextFile {
      name = "transurbanVPN.conf";
      text = builtins.concatStringsSep "\n" [
        ( builtins.readFile ./private/transurbanVPN.conf )
        ''
          script-security 2
          up ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
          up-restart
          down ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
          down-pre
        ''
      ];
    };
  in {
    transurban = {
      autoStart = false;
      #TODO authUserPass = { username = "clawson"; password = "..."; };
      #TODO updateResolvConf = true;
      config = '' config ${clientConfig} '';
    };
  };

  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    config = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users.users.corin = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "adbusers"
      "audio"
      "bumblebee"
      "cdrom"
      "docker"
      "kvm"
      "libvirtd"
      "libvirt"
      "kvm"
      "media"
      "networkmanager"
      "plugdev"
      "systemd-journal"
      "usb"
      "video"
      "wheel"
    ];
  };
  users.groups.corin.gid = 1000;
  home-manager.users.corin = { pkgs, ... }: {
    xsession.windowManager.i3 = {
      enable = true;
      config = rec {
        modifier = "Mod4";
        fonts = [ "pango:${font.monospace} 8" ];
        keybindings = lib.mkOptionDefault {
          "${modifier}+Shift+Return" = "exec i3-sensible-terminal";
          "${modifier}+Shift+c" = "kill";
          "${modifier}+p" = "exec ${pkgs.rofi}/bin/rofi -show run -lines 5 -eh 1 -width 40 -padding 10 -opacity 85 -separator-style none -hide-scrollbar -line-margin 5 -bw 0 -font '${font.monospace} 20' -sidebar-mode -monitor -4";
          "${modifier}+Shift+p" = "exec ${pkgs.rofi}/bin/rofi -show input -modi 'input:i3-input' -lines 5 -eh 1 -width 40 -padding 10 -opacity 85 -separator-style none -hide-scrollbar -line-margin 5 -bw 0 -font '${font.monospace} 20' -sidebar-mode -monitor -2";

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
          "${modifier}+Shift+q" = "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit' -f '${font.monospace} 14'";
          "${modifier}+x" = "exec ${./share/scripts/lock.sh} ${./share/resources/shield.png}";
          # audio volume control
          "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 -5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c 0 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "Shift+XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 -5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c 0 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 +5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c 0 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "Shift+XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 +5%; exec ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c 0 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute 0 toggle; exec ${pkgs.alsaUtils}/bin/amixer -c 1 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '\[off\]' && ${pkgs.volnoti}/bin/volnoti-show -m || ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c 1 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "Shift+XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute 0 toggle; exec ${pkgs.alsaUtils}/bin/amixer -c 1 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '\[off\]' && ${pkgs.volnoti}/bin/volnoti-show -m || ${pkgs.volnoti}/bin/volnoti-show $(${pkgs.alsaUtils}/bin/amixer -c 1 -M get Master | ${pkgs.gnugrep}/bin/grep -o -E '[[:digit:]]+%' | ${pkgs.coreutils}/bin/head -n 1)";
          "XF86MonBrightnessUp" = "exec ${pkgs.acpilight}/bin/xbacklight -inc 5";
          "Shift+XF86MonBrightnessUp" = "exec ${pkgs.acpilight}/bin/xbacklight -inc 5";
          "XF86MonBrightnessDown" = "exec ${pkgs.acpilight}/bin/xbacklight -dec 5";
          "Shift+XF86MonBrightnessDown" = "exec ${pkgs.acpilight}/bin/xbacklight -dec 5";
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
            fonts = [ "pango:${font.monospace} 14" ];
            position = "bottom";
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs /home/corin/.config/i3status-rust/config-default.toml";
            extraConfig = ''
              separator_symbol "  "
            '';
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
          { command = "${pkgs.picom}/bin/picom -f"; notification = false; }
          { command = "${./share/scripts/screenlayout.sh}"; notification = false; }
          { command = "${pkgs.volnoti}/bin/volnoti"; notification = false; }
          { command = "${pkgs.feh}/bin/feh -z --min-dimension 1920x1080 --bg-fill --no-fehbg ${./share/background.png}"; notification = false; }
        ];
      };
    };
    programs.i3status-rust = {
      enable = true;
      bars.default = {
        settings.theme.name = "solarized-dark";
        settings.theme.overrides.idle_bg = "${theme.base02}";
        settings.icons = {
          name = "awesome";
          overrides = {
            bat = "";
            bat_full = "";
            bat_charging = "ﮣ";
            bat_discharging = "ﮤ";
          };
        };
        blocks = [
          {
            block = "focused_window";
            max_width = 61;
          }
          {
            block = "net";
            #device = "wlan0";
          }
          {
            block = "custom";
            command = "${pkgs.curl}/bin/curl -q http://whatismyip.akamai.com/";
            on_click = "${pkgs.curl}/bin/curl -q http://whatismyip.akamai.com/";
            interval = 1800;
          }
          {
            block = "load";
            format = "{1m}";
            interval = 1;
          }
          {
            block = "memory";
            format_mem = "{MUp}%";
            format_swap = "{SUp}%";
            display_type = "memory";
            icons = true;
            clickable = false;
            interval = 5;
            warning_mem = 85;
            warning_swap = 85;
            critical_mem = 95;
            critical_swap = 95;
          }
          {
            block = "temperature";
            format = "{min}° min, {max}° max, {average}° avg";
          }
          {
            block = "time";
            interval = 60;
            format = "%a %e %b %R";
          }
          {
            block = "battery";
            device = "BAT0";
            #upower = true;
            #format = "{percentage}% {power} {time}";
            format = "{percentage}% {time}";
          }
        ];
      };
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
        window.gtk_theme_variant = "dark";
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

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      history.extended = true;
      oh-my-zsh.enable = true;
      oh-my-zsh.plugins = [ "vi-mode" "z" "git" "sudo" "adb" "per-directory-history" ];
      oh-my-zsh.theme = "phiware";
      oh-my-zsh.custom = "${./share/oh-my-zsh}";
      localVariables = {
        LOCALE_ARCHIVE = "$HOME/.nix-profile/lib/locale/locale-archive";
        GOPATH = "$(go env GOPATH)";
        GOPRIVATE = "github.com/transurbantech";
      };
      initExtra = ''
         [[ "$TERM" == "linux" ]] && setfont "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz"

         complete -C '${pkgs.awscli}/bin/aws_completer' aws
      '';
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
        syntastic
        webapi-vim
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
      ];
      extraConfig = {
        core = { excludesfile = "~/.cvsignore"; };
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
        enable = true;
        options = {
          theme = "Solarized (dark)";
        };
      };
    };

    programs.ssh.matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment = {
    pathsToLink = [ "/share/zsh" ];

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      displaylink
      unstable.thunderbolt unstable.bolt
      unstable.sof-firmware # Mic needs 1.6
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

      psmisc
      bind
      tcpdump
      bridge-utils
      inetutils
      openssl
      telnet
      libvirt
      virtviewer virt-manager
      qemu-utils qemu_kvm
      win-virtio win-qemu
      dnsmasq
      spice win-spice
      docker_compose
      terraform_0_12
      ansible
      (pkgs.packer.overrideAttrs (oldAttrs: {
	name = "packer-1.2.4";
	version = "1.2.4";

	goPackagePath = "github.com/hashicorp/packer";

	src = fetchFromGitHub {
	  owner  = "hashicorp";
	  repo   = "packer";
	  rev    = "v1.2.4";
	  sha256 = "06prn2mq199476zlxi5hxk5yn21mqzbqk8v0fy8s6h91g8h6205n";
	};
	meta = with stdenv.lib; {
	  description = "A tool for creating identical machine images for multiple platforms from a single source configuration";
	  homepage    = https://www.packer.io;
	  license     = licenses.mpl20;
	  maintainers = with maintainers; [ cstrahan zimbatm ];
	  platforms   = platforms.unix;
	};
      }))
      awscli
      awscli2
      saml2aws
      kerberos
      libkrb5
      libsecret
      lttng-ust
      patchelf
      powershell
      rlwrap
      bc
      hexedit

      # kubernetes-helm - Hold back to 2.13.1
      #(pkgs.kubernetes-helm.overrideAttrs (oldAttrs: {
      #  name = "kubernetes-helm-2.13.1";
      #  version = "2.13.1";
      #  src = fetchurl {
      #    url = "https://kubernetes-helm.storage.googleapis.com/helm-v2.13.1-linux-amd64.tar.gz";
      #    sha256 = "0nljk2y6h5bvjmc4x1knn1yb5gnikgdyvvc09dlj3jfnzhfpr5n1";
      #  };
      #}))

      oh-my-zsh
      python-with-pkgs
      python38Packages.flake8
      python38Packages.powerline
      python38Packages.pylint
      #(go_1_13.overrideAttrs (oldAttrs: rec {
      #  name = "go-${version}";
      #  version = "1.13.4";
      #  src = fetchurl {
      #    url = "https://dl.google.com/go/go${version}.src.tar.gz";
      #    sha256 = "093n5v0bipaan0qqc02wash18r625y74r4zhmjwlc9zf8asfmnwm";
      #  };
      #}))
      go_1_14
      gotools
      gopls
      go-swagger
      #(rstudioWrapper.override{ packages = with rPackages; [ devtools remotes dbplyr dplyr RProtoBuf profile ]; })
      protobuf
      bats
      grpc
      gcc
      rclone
      lm_sensors
      i3blocks
      i3status-rust
      i3lock
      alacritty
      (vim_configurable.override { python = python-with-pkgs; })
      languagetool
      proselint
      mdl
      ctags
      gdb
      rustup
      lxappearance
      numix-solarized-gtk-theme
      pop-icon-theme
      gnome3.nautilus
      gnome3.gnome-keyring
      xsel
      xorg.xwininfo
      gitAndTools.hub
      lastpass-cli
      shellcheck

      arandr
      alsa-ucm-conf
      alsa-firmware
      alsaUtils
      pavucontrol
      blueman
      glxinfo
      freerdp
      zoom-us

      surf
      spotify
      slack
      teams
      firefox
      chromium
      brave
      vscode
      gimp
      vlc
      obs-studio
      sox
      spectacle
      inkscape
      libreoffice
      cabextract
      yq
      qpdf
      qpdfview
      wgetpaste
      feh
      scrot
      nodejs
      curl
      lshw
      efibootmgr
      google-drive-ocamlfuse
      # inotify-tools
      ntfs3g
      lsof
      compton
      rofi
      twmn
      volnoti
      rxvt_unicode-with-plugins
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      global
      discount
    ];

    variables = {
      #ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      EDITOR = "vim";
      TERMINAL = "alacritty";
      TMPDIR = "/tmp";
      #DOCKER_MACHINE = "${networking.hostName}";
      #DOCKER_MACHINE_NAME = "${networking.hostName}";
      #DOCKER_HOST = "tcp://${networking.hostName}:2376";
      #DOCKER_TLS_VERIFY = "1";
      #DOCKER_CERT_PATH = "$HOME/.docker";
      # GPG_TTY = "$(tty)";
    };
  };

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts
      terminus_font
      powerline-fonts
      nerdfonts
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
  programs.adb.enable = true;
  programs.dconf.enable = true;

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

  # Allow users in the video group to change the backlight
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable Bluetooth
  services.blueman.enable = true;

  # Enable Thunderbolt security levels
  services.hardware.bolt.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
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
