# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "euler/root/nixos-20.09";
      fsType = "zfs";
    };

  fileSystems."/home/corin" =
    { device = "euler/home/corin";
      fsType = "zfs";
    };

  fileSystems."/home/corin/.cache" =
    { device = "euler/home/corin/.cache";
      fsType = "zfs";
    };

  fileSystems."/home/corin/.gem" =
    { device = "euler/home/corin/.gem";
      fsType = "zfs";
    };

  fileSystems."/home/corin/.m2" =
    { device = "euler/home/corin/.m2";
      fsType = "zfs";
    };

  fileSystems."/home/corin/.npm" =
    { device = "euler/home/corin/.npm";
      fsType = "zfs";
    };

  fileSystems."/home/corin/.qemu" =
    { device = "euler/home/corin/.qemu";
      fsType = "zfs";
    };

  fileSystems."/home/corin/.vim/swapfiles" =
    { device = "euler/home/corin/.vim/swapfiles";
      fsType = "zfs";
    };

  fileSystems."/home/corin/Downloads" =
    { device = "euler/home/corin/Downloads";
      fsType = "zfs";
    };

  fileSystems."/home/corin/src" =
    { device = "euler/home/corin/src";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "euler/nix";
      fsType = "zfs";
    };

  fileSystems."/usr/lib/node_modules" =
    { device = "euler/usr/lib/node_modules";
      fsType = "zfs";
    };

  fileSystems."/usr/local" =
    { device = "euler/usr/local";
      fsType = "zfs";
    };

  fileSystems."/usr/src" =
    { device = "euler/usr/src";
      fsType = "zfs";
    };

  fileSystems."/var/lib/docker" =
    { device = "euler/var/lib/docker";
      fsType = "zfs";
    };

  fileSystems."/var/lib/libvirt" =
    { device = "euler/var/lib/libvirt";
      fsType = "zfs";
    };

  fileSystems."/var/lib/libvirt/images" =
    { device = "euler/var/lib/libvirt/images";
      fsType = "zfs";
    };

  fileSystems."/var/lib/machines" =
    { device = "euler/var/lib/machines";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F262-18BF";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/9850379e-5323-451c-9288-0848daddd9d6"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
