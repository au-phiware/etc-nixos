# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./host-configuration.nix
    ];

  nix = {
    useSandbox = true;
    trustedUsers = [ "root" "corin" ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelModules = [
      "fuse"
    ];

    kernelParams = [
      "video=uvesafb:1024x768-32,mtrr:3,ywrap"
      "hugepages=4096"
      "vconsole.keymap=us"
      "vconsole.font=ter-powerline-v24n"
      "vt.default_red=0x07,0xdc,0x85,0xb5,0x26,0xd3,0x2a,0xee,0x00,0xcb,0x58,0x65,0x83,0x6c,0x93,0xfd"
      "vt.default_grn=0x36,0x32,0x99,0x89,0x8b,0x36,0xa1,0xe8,0x2b,0x4b,0x6e,0x7b,0x94,0x71,0xa1,0xf6"
      "vt.default_blu=0x42,0x2f,0x00,0x00,0xd2,0x82,0x98,0xd5,0x36,0x16,0x75,0x83,0x96,0xc4,0xa1,0xe3"
    ];

    extraModprobeConfig =
      ''
        options kvm-intel nested=1
        options snd-hda-intel index=1,0
      '';

    zfs = {
      #enableUnstable = true;
      #requestEncryptionCredentials = true;
      extraPools = [ "data" ];
    };
  };

  powerManagement.cpuFreqGovernor = "performance";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_AU.UTF-8";
    supportedLocales = [ "en_AU.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };
  console = {
    font = "ter-powerline-v24n";
    keyMap = "us";
  };

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  networking = {
    networkmanager.enable = true;

    #enableIPv6 = false;

    # Open ports in the firewall.
    firewall.allowedTCPPorts = [ 22 80 443 ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    #firewall.enable = false;

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  #systemd = rec {
  #  services."google-drive-ocamlfuse@" = {
  #    description = "Mount a users Google Drive under /offsite";
  #    after = [ "zfs-mount.service" "network-online.target" ];
  #    before = [ "zfs-auto-snapshot.target" ];
  #    serviceConfig = {
  #      Type = "oneshot";
  #      ExecStart = "${pkgs.google-drive-ocamlfuse}/bin/google-drive-ocamlfuse -o allow_root /offsite/%i";
  #      ExecStop = "${pkgs.fuse}/bin/fusermount -u /offsite/%i";
  #      RemainAfterExit = true;
  #      User = "%i";
  #      Group = "%i";
  #    };
  #  };
  #  services."google-drive-ocamlfuse@corin" = services."google-drive-ocamlfuse@" // {
  #    enable = true;
  #  };
  #};

  # List services that you want to enable:
  services = {
    # Enable the OpenSSH daemon.
    openssh.enable = true;

    # Enable CUPS to print documents.
    printing = {
      enable = true;
      drivers = [ pkgs.brgenml1lpr pkgs.brgenml1cupswrapper ];
    };

    # ZFS extras
    zfs = {
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

    # Enable the X11 windowing system.
    xserver = {
      enable = true;
      autorun = true;
      layout = "us";
      # xkbOptions = "eurosign:e";

      videoDrivers = [
        "intel"
        #"nvidia"
        "nouveau"
      ];

      # Enable touchpad support.
      synaptics = {
        enable = true;
        scrollDelta = -50;
        twoFingerScroll = true;
        fingersMap = [ 1 3 2 ];
      };


      # Enable the Desktop Environment.
      windowManager.i3.enable = true;
      displayManager.defaultSession = "none+i3";
      displayManager.autoLogin = {
        enable = true;
        user = "corin";
      };
      displayManager.lightdm = {
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
            font = Verdana
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

      # xautolock = {
      #   enable = true;
      #   enableNotifier = true;
      #   notifier = "${pkgs.libnotify}/bin/notify-send \"Locking in 10 seconds\"";
      #   locker = "${pkgs.i3lock}/bin/i3lock -c 151530";
      #   time = 15;
      # };
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # 32-bit support
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;

  # Nvidia
  hardware.nvidia.prime = {
    sync.enable = false;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };

  # Bluetooth
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs = {
    mtr.enable = true;
    zsh.enable = true;
    steam.enable = true;
    bash.enableCompletion = true;
    gnupg.agent.enable = true;
    gnupg.agent.enableSSHSupport = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      #extraOptions = "--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/certs/cert.pem --tlskey=/etc/docker/certs/key.pem --host tcp://0.0.0.0:2376";
    };
    libvirtd.enable = true;
    anbox.enable = true;
  };

  nixpkgs.config.packageOverrides = superPkgs: {
    unstable = import /usr/src/nixpkgs {
      config = config.nixpkgs.config;
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  environment = {
    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs;
    let
      python-with-pkgs = python38.withPackages (pypkgs: with pypkgs; [
        flake8
        msgpack
        powerline
        pynvim
        pylint
      ]);
    in [
      binutils
      pciutils
      usbutils
      moreutils
      utillinux
      efibootmgr
      lsof
      lshw
      ascii
      file
      tmux
      htop
      curl
      wget
      gnumake
      git
      mercurial
      tree
      gnupg
      zip
      unzip
      xdotool
      multipath-tools
      inotify-tools
      icu
      zlib
      openssl
      lm_sensors

      psmisc
      bind
      tcpdump
      bridge-utils
      inetutils
      telnet
      libvirt
      virtviewer
      rclone
      glxinfo
      smartmontools
      #testdisk-photorec

      freerdp
      docker_compose
      terraform_0_12
      #(pkgs.packer.overrideAttrs (oldAttrs: {
      #  name = "packer-1.2.4";
      #  version = "1.2.4";
      #  goPackagePath = "github.com/hashicorp/packer";
      #  src = fetchFromGitHub {
      #    owner  = "hashicorp";
      #    repo   = "packer";
      #    rev    = "v1.2.4";
      #    sha256 = "06prn2mq199476zlxi5hxk5yn21mqzbqk8v0fy8s6h91g8h6205n";
      #  };
      #  meta = with stdenv.lib; {
      #    description = "A tool for creating identical machine images for multiple platforms from a single source configuration";
      #    homepage    = https://www.packer.io;
      #    license     = licenses.mpl20;
      #    maintainers = with maintainers; [ cstrahan zimbatm ];
      #    platforms   = platforms.unix;
      #  };
      #}))
      awscli
      kerberos
      libkrb5
      libsecret
      jq
      yq
      imagemagick
      gcc
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
      go_1_15
      gotools
      #(rstudioWrapper.override{ packages = with rPackages; [ devtools remotes dbplyr dplyr RProtoBuf profile ]; })
      bats
      nodejs
      rustup
      protobuf
      grpc
      wgetpaste
      w3m

      oh-my-zsh
      python-with-pkgs
      python38Packages.flake8
      python38Packages.pylint
      python38Packages.powerline

      feh
      scrot
      compton
      rofi
      twmn
      volnoti
      rxvt_unicode-with-plugins
      pavucontrol
      blueman
      xsel
      arandr
      i3blocks
      i3status-rust
      i3lock
      alacritty
      languagetool
      proselint
      mdl
      ctags
      gdb
      gnome3.gnome-keyring
      xorg.xwininfo
      gitAndTools.hub
      lastpass-cli
      shellcheck

      ntfs3g
      cabextract
      google-drive-ocamlfuse

      qpdf
      qpdfview
      spotify # unfree
      slack # unfree
      teams # unfree
      _1password # unfree
      firefox
      chromium
      brave
      zoom-us # unfree
      gimp
      vlc
      sox
      obs-studio
      spectacle
      inkscape
      libreoffice
      vscode # unfree
      flatpak

      #(steam.override {
      #  nativeOnly = true; # broken
      #  #withPrimus = true;
      #})
      #steam
      #steam-run-native
      #vulkan-tools
      #lutris

      (vim_configurable.override { python = python-with-pkgs; })
      #emacs
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      global
      discount
      texlive.combined.scheme-full
      #texlive.combine {
      #  inherit (texlive) scheme-full collection-latex;
      #}
    ];

    variables = {
      ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      EDITOR = "vim";
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
      corefonts # unfree
      terminus_font
      powerline-fonts
      nerdfonts
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.corin = {
      shell = pkgs.zsh;
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
        "audio"
        "cdrom"
        "docker"
        "kvm"
        "libvirtd"
        "media"
        "networkmanager"
        "plugdev"
        "usb"
        "video"
        "systemd-journal"
        "tty"
        "lp"
        "console"
        "game"
        "qemu"
        "lpadmin"
        "android"
        "lock"
        "dialout"
        "keyboard"
      ];
    };
    groups.corin.gid = 1000;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

  system.autoUpgrade.enable = true;

}
