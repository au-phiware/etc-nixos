{
  lib,
  findutils,
  stdenv,
  steam-run,
  wineWow64Packages,
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

  src = ./.;

  setup = builtins.fetchurl {
    url = "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/Claude-Setup-x64.exe";
    sha256 = "1z3sasgvc2l5bzkcif5qyk8jqgp8l17qiki5wccpc8i8fzlsyr8x";
  };

  uv = builtins.fetchurl {
    url = "https://github.com/astral-sh/uv/releases/download/0.5.7/uv-x86_64-pc-windows-msvc.zip";
    sha256 = "0lkkkrvvf40wxr5qxkz76avsx3swdsywncd4wb2f3zw5iw6ylanb";
  };

  node = builtins.fetchurl {
    url = "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi";
    sha256 = "1vxwwrjf89i9xhjss9b5192h5gy2llvq7jf4ff75zs9va823d92z";
  };

  git = builtins.fetchurl {
    url = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe";
    sha256 = "0w6sbnymidmz8cpvw8qs53l5c1l2l2yddwhn61dm21mwvqipjli5";
  };

  meta = with lib; {
    description = "Your AI partner on desktop. Fast, focused, and designed for deep work.";
    homepage = "https://claude.ai/download";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };

  find = ''\$(${findutils}/bin/find "\$WINEPREFIX/drive_c" -wholename '*/AnthropicClaude/claude.exe' -type f -print -quit)'';
  wine = wineWow64Packages.stagingFull;
in
  stdenv.mkDerivation {
    inherit pname version setup meta;
    nativeBuildInputs = [steam-run wine winetricks samba];

    dontUnpack = true;
    dontBuild = true;
    dontPatchELF = true;

    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/claude << EOF
      #!/bin/sh
      export WINEPREFIX="\$HOME/.local/share/wineprefixes/Claude" WINEARCH=win64 WINEDEBUG=-all
      claude=${find}
      if [ -z "\$claude" ]; then
        # Initialize
        ${wine}/bin/wineboot --init

        # Copy installer
        mkdir -p \$WINEPREFIX/drive_c
        cp $setup \$WINEPREFIX/drive_c/Claude-Setup-x64.exe

        # Install .NET and Windows components
        ${winetricks}/bin/winetricks -q dotnetdesktop7 corefonts vcrun2022 ie8 ie8_kb2936068 ie8_tls12 win10
        #${wine}/bin/wine reg add 'HKCU\\Software\\Wine\\X11 Driver' /v "Decorated" /t REG_SZ /d "N" /f

        # Start required services
        ${wine}/bin/wineserver -w

        # Run Claude installer with specific flags
        ${steam-run}/bin/steam-run ${wine}/bin/wine start 'C:\\Claude-Setup-x64.exe'
        rm -f \$WINEPREFIX/drive_c/Claude-Setup-x64.exe

        # Launch native applications from Claude
        # https://gitlab.winehq.org/wine/wine/-/wikis/FAQ#how-do-i-launch-native-applications-from-a-windows-application
        ${steam-run}/bin/steam-run ${wine}/bin/wine msiexec /i $node /qn
        ${steam-run}/bin/steam-run ${wine}/bin/wine start /unix $git

        # Wait for Claude to install
        claude=${find}
        while [ ! -f "\$claude" ]; do
          sleep 2
          claude=${find}
        done
        sleep 3
      fi
      exec ${steam-run}/bin/steam-run ${wine}/bin/wine "\$claude"
      EOF
      chmod +x $out/bin/claude
    '';
  }
