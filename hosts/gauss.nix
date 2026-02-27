# Host configuration for gauss (Clevo P650HP workstation)
{ config, lib, pkgs, inputs, unstable, theme, ... }:

{
  imports = [
    ../hardware/gauss.nix
    ../system/core.nix
    ../system/desktop.nix
    ../system/coding.nix
    ../system/office.nix
    ../system/gaming.nix
  ];

  # Host identification
  networking.hostName = "gauss";
  networking.hostId = "15f562b8";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.font = "${pkgs.powerline-fonts}/share/fonts/truetype/${theme.fonts.monospace.name}.ttf";
  boot.loader.grub.backgroundColor = theme.hashColors.base03;

  # Virtual console font and keymap (ensures systemd-vconsole-setup.service succeeds)
  console = {
    keyMap = "us";
    font = lib.mkForce "ter-powerline-v24n";
    packages = [ pkgs.powerline-fonts ];
    earlySetup = true;
  };

  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelParams = [
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

  # ZFS configuration
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.zfs.extraPools = [ "gauss" ];

  # Cross-compilation support
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Networking
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
    192.168.122.21 vmware65
    192.168.122.240 DESKTOP-05NF3NK
    172.17.0.1 gauss.docker
    127.0.0.1 gauss
  '';

  # Firewall (relaxed for now - tighten later)
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 19302 ];  # Google STUN
    allowedUDPPortRanges = [
      { from = 32768; to = 60999; }  # WebRTC range
    ];
  };

  # Fingerprint reader (EgisTec ES603 — below trackpad)
  services.fprintd.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("net.reactivated.fprint.device.") == 0 &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';



  # Hardware-specific: NVIDIA
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    nvidiaSettings = true;
  };

  # NFS exports (host-specific)
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export                 192.168.122.0/24(rw,fsid=0,no_subtree_check)
    /export/datastore       192.168.122.0/24(rw,nohide,insecure,no_subtree_check)
  '';

  # Auto-connect Logi POP Mouse (BLE devices don't reconnect automatically)
  # Uses systemd restart to retry until the mouse wakes up and advertises
  systemd.services.bluetooth-connect-logi-pop = {
    description = "Auto-connect Logi POP Mouse on boot";
    after = [ "bluetooth.service" ];
    requires = [ "bluetooth.service" ];
    wantedBy = [ "bluetooth.service" ];
    unitConfig.StartLimitIntervalSec = 0;  # Retry indefinitely
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStart = pkgs.writeShellScript "bt-connect-logi-pop" ''
        # Enable LE scanning so the controller receives the mouse's advertisements
        ${pkgs.bluez}/bin/bluetoothctl scan on &
        sleep 5

        # Check if a "Logi POP Mouse" is already paired and try to connect it
        mac=$(${pkgs.bluez}/bin/bluetoothctl devices Paired \
          | ${pkgs.gnugrep}/bin/grep "Logi POP Mouse" \
          | ${pkgs.gawk}/bin/awk '{print $2}')

        if [ -n "$mac" ]; then
          result=$(${pkgs.bluez}/bin/bluetoothctl connect "$mac" 2>&1)
          echo "$result"
          if echo "$result" | grep -q "Connection successful"; then
            ${pkgs.bluez}/bin/bluetoothctl scan off
            exit 0
          fi
        fi

        # Bond may be stale — check if the mouse is visible as an unpaired device
        # (this happens when the mouse loses its LTK and resets with a new address)
        new_mac=$(${pkgs.bluez}/bin/bluetoothctl devices \
          | ${pkgs.gnugrep}/bin/grep "Logi POP Mouse" \
          | ${pkgs.gnugrep}/bin/grep -v "$(echo "$mac")" \
          | ${pkgs.gawk}/bin/awk '{print $2}' | head -1)

        if [ -n "$new_mac" ]; then
          echo "Found unpaired Logi POP Mouse at $new_mac — removing stale bond and re-pairing"
          [ -n "$mac" ] && ${pkgs.bluez}/bin/bluetoothctl remove "$mac"
          ${pkgs.bluez}/bin/bluetoothctl trust "$new_mac"
          ${pkgs.bluez}/bin/bluetoothctl pair "$new_mac" && \
            ${pkgs.bluez}/bin/bluetoothctl connect "$new_mac" && \
            ${pkgs.bluez}/bin/bluetoothctl scan off && exit 0
        fi

        ${pkgs.bluez}/bin/bluetoothctl scan off
        exit 1
      '';
    };
  };

  # This value determines the NixOS release compatibility
  system.stateVersion = "18.09";
}
