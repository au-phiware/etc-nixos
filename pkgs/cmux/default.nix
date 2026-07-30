{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:
let
  releases = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl {
        url = "https://api.github.com/repos/manaflow-ai/cmux/releases";
        sha256 = "0pdxwcz8kki51jzskvxs07bzzqj675r91f153p40rgz0r69xzx3g";
      }
    )
  );
  release = builtins.head (
    builtins.filter (release: !(release.draft || release.prerelease)) releases
  );
  artifact = builtins.head (builtins.filter (asset: asset.name == "cmux-macos.dmg") release.assets);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cmux";
  version = builtins.substring 1 (builtins.stringLength release.tag_name - 1) release.tag_name;

  src = fetchurl {
    url = artifact.browser_download_url;
    sha256 = artifact.digest;
  };

  dontPatchELF = true;
  dontStrip = true;
  nativeBuildInputs = [ _7zz ];

  unpackPhase = ''
    runHook preUnpack
    7zz x $src
    runHook postUnpack
  '';

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -r cmux.app $out/Applications/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Ghostty-based macOS terminal with vertical tabs and notifications for AI coding agents";
    homepage = "https://github.com/manaflow-ai/cmux";
    license = licenses.agpl3Plus;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
})
