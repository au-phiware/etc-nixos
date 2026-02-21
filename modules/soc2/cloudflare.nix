{
  config,
  lib,
  pkgs,
  ...
}: {
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
        desktop-file-utils
      ];
    };

    # Add a systemd temp file for WARP config
    systemd.tmpfiles.rules = [
      "d /var/lib/cloudflare-warp 0755 root root -"
      "f /var/lib/cloudflare-warp/settings.json 0644 root root -"
    ];

    # Create the WARP settings file with IPv4 preference
    system.activationScripts.cloudflare-warp-settings = {
      text = ''
        mkdir -p /var/lib/cloudflare-warp
        cat > /var/lib/cloudflare-warp/settings.json << EOF
{
  "auto_connect": 1,
  "fallback_domains": [],
  "service": {
    "disable_ipv6": true,
    "prefer_ipv4": true
  }
}
EOF
      '';
      deps = [];
    };

    systemd.services.cloudflare-warp = {
      description = "Cloudflare WARP";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
        Restart = "always";
        Environment = "WARP_CONFIG_DIR=/var/lib/cloudflare-warp";
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

    virtualisation.docker.daemon.settings = {
      "dns" = ["8.8.8.8"];
      "bip" = "192.168.237.1/24";
      "default-address-pools" = builtins.map (i: {
        "base" = "192.168.${toString i}.0/24";
        "size" = 24;
      }) (lib.range 238 254);
    };
  };
}
