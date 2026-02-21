{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./crowdstrike/module.nix
    ./cloudflare.nix
    ./intune.nix
  ];

  # CrowdStrike CID must be configured in your host configuration
  # See README.md for usage instructions

  environment = {
    systemPackages = with pkgs; [
      _1password-cli
      _1password-gui
    ];
  };
}
