{ config, pkgs, lib, ... }:
{
  options.services.pulse = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Whether to enable Pulse.";
      example = false;
    };

    serverName = lib.mkOption {
      type = lib.types.str;
      default = "creativecreature-pulse-server";
      description = "Server name for Pulse";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 49152;
      description = "Port number for Pulse server";
    };

    uri = lib.mkOption {
      type = lib.types.str;
      default = "mongodb://localhost:27017";
      description = "MongoDB URI for Pulse";
    };

    db = lib.mkOption {
      type = lib.types.str;
      default = "creativecreature-pulse";
      description = "Database name for Pulse";
    };
  };

  config = let
    pulse = pkgs.callPackage ./default.nix {
      inherit (config.services.pulse) serverName port uri db;
      inherit (config.networking) hostName;
    };
  in lib.mkIf config.services.pulse.enable {
    services.mongodb = {
      enable = true;
    };

    systemd.services.creativecreature-pulse = {
      description = "Pulse Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "mongodb.service" ];
      requires = [ "mongodb.service" ];
      serviceConfig = {
        ExecStart = "${pulse}/bin/pulse-server";
        Restart = "always";
        StandardError = "journal";
        StandardOutput = "journal";
        StateDirectory = "pulse";
        WorkingDirectory = "/var/lib/pulse";
        Environment = "HOME=/var/lib/pulse";
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        pulseVimPlugin = (pkgs.callPackage ./vim-plugin.nix {
          inherit pkgs pulse;
        });
      })
    ];
  };
}
