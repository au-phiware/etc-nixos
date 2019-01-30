# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstableTarball =
    fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;
in
{
  nix.nixPath = [
    "nixpkgs=/usr/src/nixpkgs"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.kernelModules = [ "i915" ];
    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "hugepages=4096"
      "vconsole.keymap=us"
      "vconsole.font=ter-powerline-v24n"
      "vt.default_red=0x07,0xdc,0x85,0xb5,0x26,0xd3,0x2a,0xee,0x00,0xcb,0x58,0x65,0x83,0x6c,0x93,0xfd"
      "vt.default_grn=0x36,0x32,0x99,0x89,0x8b,0x36,0xa1,0xe8,0x2b,0x4b,0x6e,0x7b,0x94,0x71,0xa1,0xf6"
      "vt.default_blu=0x42,0x2f,0x00,0x00,0xd2,0x82,0x98,0xd5,0x36,0x16,0x75,0x83,0x96,0xc4,0xa1,0xe3"
    ];
    extraModprobeConfig =
      ''
        options kvm ignore_msrs=1
        options kvm-intel nested=1
        options kvm-intel ept=1
        options kvm-intel enable_shadow_vmcs=1
        options kvm-intel enable_apicv=1
      '';
    supportedFilesystems = [ "zfs" ];
    zfs = {
      enableUnstable = true;
      requestEncryptionCredentials = true;
      extraPools = [ "gauss" ];
    };
  };

  # zfs-import-gauss.serviceConfig.RequiresMountsFor = "/root/gauss.key";

  # Swap
  # zramSwap = {
  #   enable = true;
  #   memoryPercent = 20;
  #   numDevices = 4;
  #   priority = 10;
  # };

  powerManagement.cpuFreqGovernor = "performance";

  # Select internationalisation properties.
  i18n = {
    consoleFont = "ter-powerline-v24n";
    # consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_AU.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  networking = {
    hostName = "gauss"; # Define your hostname.
    hostId = "15f562b8";
    networkmanager.enable = true;
    nameservers = [ "172.23.0.2" ];

    extraHosts =
      ''
        192.168.122.21 vmware65
        172.17.0.1 gauss.docker
      '';

    # enableIPv6 = true;


    # Open ports in the firewall.
    firewall.allowedTCPPorts = [ 22 ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    firewall.enable = false;

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  # List services that you want to enable:
  services = {
    # Enable the OpenSSH daemon.
    openssh.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;

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

      videoDrivers = [ "nvidia" ];

      # Enable touchpad support.
      synaptics = {
        enable = true;
        scrollDelta = -50;
        twoFingerScroll = true;
      };

      # displayManager.job.preStart =
      #   ''
      #     ${config.boot.kernelPackages.bbswitch}/bin/discrete_vga_poweron
      #   '';

      # Enable the Desktop Environment.
      displayManager.slim = {
        enable = true;
        defaultUser = "corin";
        theme = ./share/slim/themes/turing;
      };
      # desktopManager.plasma5.enable = true;
      windowManager.i3.enable = true;

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

  # Display
  hardware.cpu.intel.updateMicrocode = true;
  hardware.nvidia = {
    modesetting.enable = true;
    optimus_prime = {
      enable = true;
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };

  # hardware.nvidiaOptimus.disable = true;
  # hardware.opengl = {
  #   enable = true;
  #   driSupport32Bit = true;
  #   extraPackages = with pkgs; [
  #     vaapiIntel
  #     vaapiVdpau
  #     libvdpau-va-gl
  #   ];
  # };
  # hardware.bumblebee = {
  #   enable = true;
  #   connectDisplay = false;
  # };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    extraConfig =
      ''
        [general]
        Enable=Source,Sink,Media,Socket
      '';
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
    bash.enableCompletion = true;
    gnupg.agent.enable = true;
    gnupg.agent.enableSSHSupport = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      extraOptions = "--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/certs/cert.pem --tlskey=/etc/docker/certs/key.pem --host tcp://0.0.0.0:2376";
    };
    libvirtd.enable = true;
  };

  nixpkgs.config.packageOverrides = superPkgs: {
    unstable = import unstableTarball {
      config = config.nixpkgs.config;
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment = {
    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      pciutils
      usbutils
      file
      tmux
      htop
      wget
      vim
      gnumake
      git
      mercurial
      jq
      tree
      gnupg
      unzip
      imagemagick

      psmisc
      bind
      tcpdump
      bridge-utils
      inetutils
      openssl
      telnet
      libvirt
      virtviewer
      docker_compose
      kubectl
      # google-drive-ocamlfuse

      oh-my-zsh
      python27Packages.powerline
      go_1_11
      protobuf
      bats
      grpc
      gcc
      rclone
      lm_sensors
      i3blocks
      unstable.i3status-rust

      arandr
      pavucontrol
      blueman
      glxinfo
      freerdp

      i3lock
      spotify
      slack
      firefox
      chromium
      vscode
      gimp
      vlc
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
      i3blocks
      lemonbar
      rofi
      twmn
      volnoti
      rxvt_unicode-with-plugins
    ];

    variables = {
      ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      EDITOR = "vim";
      TMPDIR = "/tmp";
      DOCKER_MACHINE = "gauss";
      DOCKER_MACHINE_NAME = "gauss";
      DOCKER_HOST = "tcp://gauss:2376";
      DOCKER_TLS_VERIFY = "1";
      DOCKER_CERT_PATH = "$HOME/.docker";
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
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.corin = {
      shell = pkgs.zsh;
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "audio"
        "bumblebee"
        "cdrom"
        "docker"
        "kvm"
        "libvirtd"
        "media"
        "networkmanager"
        "plugdev"
        "usb"
        "video"
        "wheel"
      ];
    };
    groups.corin.gid = 1000;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}
