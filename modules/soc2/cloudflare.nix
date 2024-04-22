{ config, lib, pkgs, ... }: {
  options = {
    cloudflare-warp.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Whether to enable Cloudflare WARP.";
      example = false;
    };
  };

  config = lib.mkIf config.cloudflare-warp.enable {
    environment = {
      systemPackages = with pkgs; [
        cloudflare-warp
      ];
    };

    systemd.services.cloudflare-warp = {
      description = "Cloudflare WARP";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
        Restart = "always";
      };
    };

    security.pki.certificateFiles = [
      (builtins.fetchurl {
        url = "https://developers.cloudflare.com/cloudflare-one/static/Cloudflare_CA.pem";
        # Use nix-prefetch-url 'https://developers.cloudflare.com/cloudflare-one/static/Cloudflare_CA.pem'
        # Fingerprint=BB:2D:B6:3D:6B:DE:DA:06:4E:CA:CB:40:F6:F2:61:40:B7:10:F0:6C
        sha256 = "1mal8zm9m7a2pb1n9j361xly3vlk1a99s3hbci9jvkvvmrivx7gf";
      })
    ];
  };
}
