{ stdenv, pkgs, pulse, ... }:
stdenv.mkDerivation {
  name = "pulse-vim-plugin";
  src = pulse.src;

  dontBuild = true;

  patchPhase = ''
    substituteInPlace plugin/pulse.vim \
      --replace-fail "['pulse-client']" "['${pulse}/bin/pulse-client']" \
      --replace-quiet "system('uuidgen')" "system('${pkgs.util-linux}/bin/uuidgen')"
  '';

  installPhase = ''
    mkdir -p $out/plugin
    cp plugin/pulse.vim $out/plugin/pulse.vim
  '';
}
