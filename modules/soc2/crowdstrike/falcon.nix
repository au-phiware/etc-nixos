{ pkgs, stdenv, lib, dpkg, zlib, ... }:

let
  version = "7.05.0";
  build = "16004";
  arch = "amd64";

in

stdenv.mkDerivation rec {
  name = "falcon-sensor";

  buildInputs = [ dpkg zlib ];

  sourceRoot = ".";

  src = builtins.fetchurl {
    # Download from https://circlet1.sharepoint.com/:u:/r/sites/security_scope_soc2/Shared%20Documents/Versent-Endpoint-Linux.zip
    # Unzip and place in /opt/CrowdStrikeDistribution
    url = "file:///opt/CrowdStrikeDistribution/${name}_${version}-${build}_${arch}.deb";
    # Replace with the results of: nix-prefetch-url "file:///opt/CrowdStrikeDistribution/falcon-sensor_*-*_amd64.deb"
    sha256 = "1l06807wljp7zbrfmzr16abmr25k5hdk1rxibibjykf80ngzazm3";
  };

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir $out
    cp -r . $out
  '';

  meta = with lib; {
    description = "CrowdStrike Falcon Sensor";
    homepage    = "https://www.crowdstrike.com/";
    license     = licenses.unfree;
    platforms   = platforms.linux;
    maintainers = [];
  };
}
