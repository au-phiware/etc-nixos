# Shamelessly copied and then hacked into shape from https://github.com/thall/nixos/raw/9c46b567ffbbbb9c9b9a0012e3882364a2ec47c0/thinkpad_t14s/nixos/crowdstrike/module.nix
{
  config,
  lib,
  pkgs,
  buildFHSUserEnv,
  libnl,
  openssl,
  zlib,
  ...
}:
with lib; let
  falcon = pkgs.callPackage ./falcon.nix {};

  falcon-env = pkgs.buildFHSUserEnv {
    name = "falcon-env";
    targetPkgs = pkgs: [pkgs.libnl pkgs.openssl pkgs.zlib];

    extraInstallCommands = ''
      ln -s ${falcon}/* $out/
    '';
  };
in {
  options = {
    crowdstrike = {
      enable = mkOption {
        default = true;
        type = types.bool;
        description = "Whether to enable CrowdStrike Falcon Sensor";
        example = false;
      };
      cid = mkOption {
        type = types.str;
        description = ''
          The CrowdStrike customer ID.
        '';
      };
    };
  };

  config = mkIf config.crowdstrike.enable {
    systemd.services.falcon-sensor = {
      description = "CrowdStrike Falcon Sensor";
      unitConfig.DefaultDependencies = false;
      after = ["local-fs.target"];
      conflicts = ["shutdown.target"];
      before = ["sysinit.target" "shutdown.target"];
      serviceConfig = {
        ExecStartPre = "${falcon-env}/bin/falcon-env -c \"${pkgs.rsync}/bin/rsync --verbose --ignore-existing --links --recursive --mkpath ${falcon-env}/opt/CrowdStrike/ /opt/CrowdStrike/; /opt/CrowdStrike/falconctl -s -f --cid='${config.crowdstrike.cid}'\"";
        ExecStart = "${falcon-env}/bin/falcon-env -c \"${falcon-env}/opt/CrowdStrike/falcond\"";
        Type = "forking";
        PIDFile = "/run/falcond.pid";
        Restart = "no";
        TimeoutStopSec = "60s";
        KillMode = "control-group";
        KillSignal = "SIGTERM";
      };
      wantedBy = ["multi-user.target"];
    };
  };
}
