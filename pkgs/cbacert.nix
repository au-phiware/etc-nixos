
{ stdenv, requireFile }:
stdenv.mkDerivation (finalAttrs: rec {
  pname = "cbacert";
  version = "3.9.3";
  src = requireFile rec {
    name = "cbacert-darwin-amd64.tar.gz";
    hash = "sha256:1z4j72cf8a2zccqsn5vcqp74c01svz3jfip7r6za2s4dcq8azf8x";
    message = ''
      In order to install the CBA certificate manager tool, you must first
      login and download the binary from Artifactory.

      https://artifactory.internal.cba/artifactory/cloudservices-cert-management-engineering-generic/cbacert-cli/v${version}/${name}

      Once downloaded, please run the following command before re-running the
      installation:

      nix-prefetch-url file://\$PWD/${name}
    '';
  };

  installPhase = ''
    runHook preInstall
    install -D cbacert $out/bin/cbacert
    runHook postInstall
  '';

  dontStrip = true;
  dontPatchELF = true;

  meta = {
    description = "Internal CBA tool to assist in adopting automated Certificate Lifecycle Management.";
    homepage = "https://commbank.atlassian.net/wiki/spaces/CEM/pages/816690419/How+to+use+cbacert+cli";
    platforms = [ "aarch64-darwin" ];
  };
})
