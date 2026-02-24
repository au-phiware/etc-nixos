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
        sha256 = "sha256:1xmzvq100lbvv508n767gsglawcrhmdfmm1dpwadpqfkvlgzps32";
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
    hash = "sha256:0724snbfj4ixxl3n1cn9i7lj9ixm7lf6934k8l6nalysmwdzvsxc";
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
