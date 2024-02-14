{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation rec {
  pname = "monaspace";
  version = "1.000";
  src = fetchFromGitHub {
    owner = "githubnext";
    repo = "monaspace";
    rev = "v${version}";
    hash = "sha256-Zo56r0QoLwxwGQtcWP5cDlasx000G9BFeGINvvwEpQs=";
  };
  installPhase = ''
    runHook preInstall
    find fonts/otf -name '*.otf' -exec install -m444 -Dt $out/share/fonts {} \;
    find fonts/variable -name '*.ttf' -exec install -m444 -Dt $out/share/fonts {} \;
    runHook postInstall
  '';
  meta = with lib; {
    homepage = "https://github.com/githubnext/monaspace";
    description = "The Monaspace type system is a monospaced type superfamily with some modern tricks up its sleeve.";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
