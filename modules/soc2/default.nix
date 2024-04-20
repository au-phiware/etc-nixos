{ config, lib, pkgs, ... }: {
  imports = [
    ./crowdstrike/module.nix
    ./cloudflare.nix
  ];

  cloudflare-warp.enable = true;

  crowdstrike = {
    enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      _1password _1password-gui
    ];
  };
}
