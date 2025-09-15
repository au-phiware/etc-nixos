{
  lib,
  findutils,
  stdenv,
  wineWowPackages,
  winetricks,
  samba,
}: let
  inherit (stdenv.hostPlatform) system;

  pname = "teams";

  version = "1.7.00.7956";

  src = builtins.fetchurl {
    url = "https://statics.teams.cdn.office.net/production-windows/${version}/Teams_windows.msi";
    sha256 = "1i11l8rw6hh559cz8mvgakg8ll7wjcdx1gdqf8dm644lsdhil8sx"; # Replace with the actual SHA256 hash
  };

  meta = with lib; {
    description = "Microsoft Teams";
    homepage = "https://teams.microsoft.com";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };

  find = ''\$(${findutils}/bin/find "\$WINEPREFIX/drive_c/Program Files" \$WINEPREFIX/drive_c -name 'Teams.exe' -type f -print -quit)'';
  wine = wineWowPackages.full;
in
  stdenv.mkDerivation {
    inherit pname version src meta;
    nativeBuildInputs = [wine winetricks samba];

    dontUnpack = true;
    dontBuild = true;
    dontPatchELF = true;

    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/teams << EOF
      #!/bin/sh
      export WINEPREFIX="\$HOME/.local/share/Teams" WINEARCH=win64
      teams=${find}
      if [ -z "\$teams" ]; then
        ${winetricks}/bin/winetricks -q settings windowmanagerdecorated=n
        ${winetricks}/bin/winetricks -q win11 corefonts d3dx9 vcrun2019
        ${wine}/bin/wine $src
      else
        exec -a Teams.exe ${wine}/bin/wine "\$teams"
      fi
      EOF
      chmod +x $out/bin/teams
    '';
  }
