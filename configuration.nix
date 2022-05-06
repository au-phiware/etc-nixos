# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:
let
  # nix-channel --add https://nixos.org/channels/nixos-unstable unstable
  #unstable = import <unstable> { config.allowUnfree = true; };
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
      # nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
      <home-manager/nixos>
    ];

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
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1
    options kvm-intel nested=1
    options kvm-intel ept=1
    options kvm-intel enable_shadow_vmcs=1
    options kvm-intel enable_apicv=1
  '';
  boot.supportedFilesystems = [ "zfs" ];
  #boot.zfs.enableUnstable = true;
  boot.zfs.requestEncryptionCredentials = true;
  boot.zfs.extraPools = [ "gauss" ];
  #boot.blacklistedKernelModules = [ "snd-soc-dmic" ];

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  networking.hostId = "15f562b8";
  networking.hostName = "gauss";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager = {
    enable = true;
    insertNameservers = [ "172.27.0.2" ];
  };
  networking.extraHosts =
    ''
      192.168.122.21 vmware65
      192.168.122.240 DESKTOP-05NF3NK
      172.17.0.1 gauss.docker
      127.0.0.1 gauss
    '';

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.enableIPv6 = false;
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  #networking.useDHCP = false;
  #networking.dhcpcd.wait = "background";
  #networking.interfaces.wlp0s20f3.useDHCP = true;

  powerManagement.cpuFreqGovernor = "performance";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.supportedLocales = [ "en_AU.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  console = {
    # font = "Lat2-Terminus16";
    font = "ter-powerline-v24n";
    #font = "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v24b.psf.gz";
    keyMap = "us";
  };

  # Enable a Desktop Environment.
  services.xserver.enable = true;
  services.xserver.autorun = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.synaptics = {
    enable = true;
    scrollDelta = -50;
    twoFingerScroll = true;
    fingersMap = [ 1 3 2 ];
  };
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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  nixpkgs.config.pulseaudio = true;

  # Display
  hardware.cpu.intel.updateMicrocode = true;
  hardware.nvidia = {
    modesetting.enable = true;
    prime = {
      sync.enable = true;
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };

  # Enable Portals
  #xdg.portal.enable = true;
  #services.pipewire.enable = true;

  # Enable resolved (needed by OpenVPN)
  #services.resolved.enable = true;

  # Enable lorri
  services.lorri.enable = true;

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
      "libvirt"
      "libvirtd"
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
    home.packages = with pkgs; [
      alacritty # Alacritty is the default terminal in the config
      rofi # Dmenu replacement
      arandr
    ];

    services.kanshi = {
      enable = false;
      # Run `swaymsg -t get_outputs` to see present outputs
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
      #oh-my-zsh.theme = "phiware";
      #oh-my-zsh.custom = "${./share/oh-my-zsh}";
      shellAliases = {
        nix-shell = ''nix-shell --command "$SHELL"'';
      };
      localVariables = {
        LOCALE_ARCHIVE = "$HOME/.nix-profile/lib/locale/locale-archive";
        GOPATH = "$(go env GOPATH)";
        GOPRIVATE = "github.com/transurbantech";
	PATH = "$PATH:$HOME/.cargo/bin";
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
      nix-direnv.enableFlakes = true;
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
        # direnv is often a personal choice
        "/.envrc"
        "/.direnv/"
        # For when nix is a personal choice
        "/result"
      ];
      extraConfig = {
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

    # programs.ssh.matchBlocks = {
    #   "github.com" = {
    #     hostname = "ssh.github.com";
    #     user = "git";
    #     port = 443;
    #   };
    # };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment = {
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
      xdg-desktop-portal-wlr
      lsd

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
      #spice win-spice
      docker_compose
      terraform_0_12
      awscli2
      kerberos
      libkrb5
      libsecret
      lttng-ust
      patchelf
      powershell
      rlwrap
      bc
      hexedit

      i3status-rust
      i3lock
      i3blocks

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
      go_1_15
      gotools
      gopls
      #(rstudioWrapper.override{ packages = with rPackages; [ devtools remotes dbplyr dplyr RProtoBuf profile ]; })
      protobuf
      bats
      grpc
      rclone
      lm_sensors
      (vim_configurable.override { python = python-with-pkgs; })
      languagetool
      proselint
      mdl
      universal-ctags
      gdb
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
      lastpass-cli
      shellcheck

      rustup
      clang
      cargo-fuzz
      cargo-watch
      cargo-edit

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
      ntfs3g
      lsof
      compton
      twmn
      volnoti
      rxvt_unicode-with-plugins
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      global
      discount

      minecraft
    ];

    variables = {
      #ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      EDITOR = "vim";
      TMPDIR = "/tmp";
      DOCKER_MACHINE = "${networking.hostName}";
      DOCKER_MACHINE_NAME = "${networking.hostName}";
      DOCKER_HOST = "tcp://${networking.hostName}:2376";
      DOCKER_TLS_VERIFY = "1";
      DOCKER_CERT_PATH = "$HOME/.docker";
      # GPG_TTY = "$(tty)";
      XDG_PICTURES_DIR = "$HOME/Pictures";
    };
  };

  fonts = {
    fontDir.enable = true;
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
  #programs.adb.enable = true;
  programs.dconf.enable = true;
  programs.steam.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      extraOptions = "--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/certs/cert.pem --tlskey=/etc/docker/certs/key.pem --host tcp://0.0.0.0:2376";
    };
    #anbox.enable = true;
    libvirtd.enable = true;
  };

  # List services that you want to enable:

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
  system.autoUpgrade.enable = true;
}
