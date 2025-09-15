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

  crowdstrike = {
    cid = "B28634B33F2947E6BEF94F798ED280E8-05";
  };

  environment = {
    systemPackages = with pkgs; [
      _1password-cli
      _1password-gui
    ];
  };
}
