{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./crowdstrike/module.nix
    ./cloudflare.nix
  ];

  crowdstrike = {
  };

  environment = {
    systemPackages = with pkgs; [
      _1password
      _1password-gui
    ];
  };
}
