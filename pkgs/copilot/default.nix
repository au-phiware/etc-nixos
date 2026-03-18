{
  lib,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  nodejs,
}:

let
  pkgData = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl {
        url = "https://registry.npmjs.org/@github/copilot";
        sha256 = "sha256:0ncjm26739rjglf205rdj1agpn17nrbd1crb6wkp0xic07dc35av";
      }
    )
  );
  version = pkgData.dist-tags.latest;
in
stdenvNoCC.mkDerivation {
  pname = "github-copilot-cli";
  version = "${version}";

  src = fetchzip {
    url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
    hash = "sha256:0ij63dbpsrzxgcbzd3lg5fz2hwpjgcj0gr2qpl6m895m5gq1kg4d";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@github/copilot
    cp -r . $out/lib/node_modules/@github/copilot/

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/copilot \
    --add-flags "$out/lib/node_modules/@github/copilot/index.js"

    runHook postInstall
  '';

  meta = {
    description = "GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal";
    homepage = "https://github.com/github/copilot-cli";
    changelog = "https://github.com/github/copilot-cli/blob/v${version}/changelog.md";
    downloadPage = "https://www.npmjs.com/package/@github/copilot";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ dbreyfogle ];
    mainProgram = "copilot";
  };
}
