{ lib, stdenv, fetchurl }:

let
  # See GCS_BUCKET in https://claude.ai/install.sh
  gcs =
    "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

  # Auto version lookup: update these two hashes when bumping.
  #   nix-prefetch-url "${gcs}/latest"
  #   nix-prefetch-url "${gcs}/$(curl -fsSL ${gcs}/latest)/manifest.json"
  version = builtins.readFile (builtins.fetchurl {
    url = "${gcs}/latest";
    sha256 = "1hr9h4x9hch3q92wxdb4h3g1r32rch0anph96l0vqhln19why4ki";
  });

  manifest = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "${gcs}/${version}/manifest.json";
    sha256 = "09mg06lq8dwkp5q63h775x0rmiqwji6ib2gii0jdal2gmavhmkd2";
  }));

  nixPlatformToGcs = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  gcsPlatform = nixPlatformToGcs.${stdenv.hostPlatform.system} or (throw
    "Unsupported system: ${stdenv.hostPlatform.system}");

  # Platform checksum (hex sha256) is extracted from the manifest automatically
  checksum = manifest.platforms.${gcsPlatform}.checksum;
in stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${gcs}/${version}/${gcsPlatform}/claude";
    sha256 = checksum;
  };

  dontUnpack = true;

  # Bun single-file executables embed bytecode after the ELF sections.
  # autoPatchelfHook / patchELF / strip rewrite the binary and discard that
  # trailing data, so we patch only the interpreter ourselves.
  dontPatchELF = true;
  dontStrip = true;

  nativeBuildInputs = [ ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m 755 $src $out/bin/claude
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/claude
    ''}
    runHook postInstall
  '';

  meta = {
    description = "Claude Code - an agentic coding tool by Anthropic";
    homepage = "https://docs.anthropic.com/en/docs/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = builtins.attrNames nixPlatformToGcs;
  };
}
