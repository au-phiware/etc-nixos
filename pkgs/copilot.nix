# GitHub Copilot CLI
# Brings the power of Copilot coding agent directly to your terminal
{ lib, stdenvNoCC, fetchzip, makeWrapper, nodejs, }:

let
  pkgData = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "https://registry.npmjs.org/@github/copilot";
    # nix-prefetch-url https://registry.npmjs.org/@github/copilot
    sha256 = "sha256:16jn7fdf6xzgj3bhkk1z6v5lsjjrya3r8gr7r0r50ybyccllrsqj";
  }));
  version = pkgData.dist-tags.latest;
in stdenvNoCC.mkDerivation {
  pname = "github-copilot-cli";
  version = "${version}";

  src = fetchzip {
    url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
    # nix-prefetch-url --unpack "https://registry.npmjs.org/@github/copilot/-/copilot-$(curl -s https://registry.npmjs.org/@github/copilot | jq -r '.["dist-tags"].latest').tgz"
    hash = "sha256:1aimpbmwi32x9547g6nmad4979x551kccavhyrbkch6yas9l7y21";
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
    description =
      "GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal";
    homepage = "https://github.com/github/copilot-cli";
    changelog =
      "https://github.com/github/copilot-cli/blob/v${version}/changelog.md";
    downloadPage = "https://www.npmjs.com/package/@github/copilot";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ dbreyfogle ];
    mainProgram = "copilot";
  };
}
