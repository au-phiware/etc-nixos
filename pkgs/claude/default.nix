{
  lib,
  findutils,
  stdenv,
  wineWowPackages,
  winetricks,
  samba,
}: let
  inherit (stdenv.hostPlatform) system;

  pname = "claude-desktop";

  version =
    {
      x86_64-linux = "0.0.0";
    }
    .${system}
    or (throw "Claude for Desktop does not support system: ${system}");

  src = builtins.fetchurl {
    url = "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/Claude-Setup-x64.exe";
    sha256 = "1z3sasgvc2l5bzkcif5qyk8jqgp8l17qiki5wccpc8i8fzlsyr8x"; # Replace with the actual SHA256 hash
  };

  meta = with lib; {
    description = "Your AI partner on desktop. Fast, focused, and designed for deep work.";
    homepage = "https://claude.ai/download";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };

  find = ''\$(${findutils}/bin/find "\$WINEPREFIX/drive_c/Program Files" \$WINEPREFIX/drive_c -name 'Claude.exe' -type f -print -quit)'';
  wine = wineWowPackages.waylandFull;
in
  stdenv.mkDerivation {
    inherit pname version src meta;
    nativeBuildInputs = [wine winetricks samba];

    dontUnpack = true;
    dontBuild = true;
    dontPatchELF = true;

    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/claude << EOF
      #!/bin/sh
      export WINEPREFIX="\$HOME/.local/share/wineprefixes/Claude" WINEARCH=win64
      claude=${find}
      if [ -z "\$claude" ]; then
        ${wine}/bin/wineboot -i
        ${wine}/bin/winecfg -v win7
        ${winetricks}/bin/winetricks -q arch=64 prefix=Claude
        ${winetricks}/bin/winetricks -q settings windowmanagerdecorated=n
        ${winetricks}/bin/winetricks -q win7
        ${winetricks}/bin/winetricks -q corefonts
        ${winetricks}/bin/winetricks -q dotnet48
        ${winetricks}/bin/winetricks -q vcrun2019
        ${winetricks}/bin/winetricks -q mfc42
        ${winetricks}/bin/winetricks -q comctl32 comctl32ocx
        ${winetricks}/bin/winetricks -q ole32
        ${winetricks}/bin/winetricks -q oleaut32
        ${winetricks}/bin/winetricks -q dxvk
        ${winetricks}/bin/winetricks -q d3dx9
        ${winetricks}/bin/winetricks -q msxml6
        ${winetricks}/bin/winetricks -q riched20
        ${winetricks}/bin/winetricks -q riched30
        ${winetricks}/bin/winetricks -q ie8
        ${winetricks}/bin/winetricks -q mshtml
        ${wine}/bin/wine $src
      else
        exec -a Claude.exe ${wine}/bin/wine "\$claude"
      fi
      EOF
      chmod +x $out/bin/claude
    '';
  }
