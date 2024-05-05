{
  lib,
  findutils,
  stdenv,
  wineWowPackages,
  winetricks,
  samba,
}: let
  inherit (stdenv.hostPlatform) system;

  pname = "kosmik";

  version =
    {
      x86_64-linux = "2.7.1";
    }
    .${system}
    or (throw "kosmik does not support system: ${system}");

  src = builtins.fetchurl {
    url = "https://play.kosmik.app/electron/Kosmik-Intel-setup.exe";
    sha256 = "19wf738hfszn5xrbyik4qa9x9gffvv43xnq678g7hwdha1cfnza8"; # Replace with the actual SHA256 hash
  };

  meta = with lib; {
    description = "The space for your creative assests";
    homepage = "https://www.kosmik.app";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };

  find = ''\$(${findutils}/bin/find "\$WINEPREFIX/drive_c/Program Files" \$WINEPREFIX/drive_c -name 'Kosmik.exe' -type f -print -quit)'';
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
      cat > $out/bin/kosmik << EOF
      #!/bin/sh
      export WINEPREFIX="\$HOME/.local/share/wineprefixes/Kosmik" WINEARCH=win64
      kosmik=${find}
      if [ -z "\$kosmik" ]; then
        ${winetricks}/bin/winetricks -q arch=64 prefix=Kosmik
        ${winetricks}/bin/winetricks -q settings windowmanagerdecorated=n
        ${winetricks}/bin/winetricks -q win11 corefonts d3dx9 vcrun2019
        ${wine}/bin/wine $src
      else
        exec -a Kosmik.exe ${wine}/bin/wine "\$kosmik"
      fi
      EOF
      chmod +x $out/bin/kosmik
    '';
  }
