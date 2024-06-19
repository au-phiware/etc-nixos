{ stdenv, pkgs, hostName, serverName, port, db, uri, ... }:
let
  pulseEnv = pkgs.writeTextFile {
    name = "pulse-envrc";
    text = ''
      export HOSTNAME=${hostName}
      export SERVER_NAME=${serverName}
      export PORT=${toString port}
      export DB=${db}
      export URI=${uri}
    '';
  };
in pkgs.buildGoModule {
  pname = "pulse";
  version = "v0.1.5-5-gbc4b6da";

  src = pkgs.fetchFromGitHub {
    owner = "creativecreature";
    repo = "pulse";
    rev = "bc4b6dacaf7c2cec37b95de014e2c5785e20610e";
    sha256 = "sha256-TMX+hV+n7d2dDc5qnzCXv8LMlvijmedCEt7rv7yO7gY=";
  };

  vendorHash = null;

  configurePhase = ''
      cp ${pulseEnv} .envrc
      export GOCACHE=$TMPDIR/go-cache
  '';

  buildPhase = ''
      make build/server build/client
  '';

  installPhase = ''
      install -Dm755 ./bin/pulse-server $out/bin/pulse-server
      install -Dm755 ./bin/pulse-client $out/bin/pulse-client
  '';
}
