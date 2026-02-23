{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  gcs = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

  # Auto version lookup: update these two hashes when bumping.
  #   nix-prefetch-url "${gcs}/latest"
  #   nix-prefetch-url "${gcs}/$(curl -fsSL ${gcs}/latest)/manifest.json"
  version = builtins.readFile (builtins.fetchurl {
    url = "${gcs}/latest";
    sha256 = "06c8v49iggy9z221i9lmyfqxk25imq3drcdnhvylqblgjmfiwqy0";
  });

  manifest = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "${gcs}/${version}/manifest.json";
    sha256 = "1zjcsmh484c74r8qd6cvsldj5b5fqahkc67bmx84bxd9hmz71hc3";
  }));

  nixPlatformToGcs = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  gcsPlatform = nixPlatformToGcs.${stdenvNoCC.hostPlatform.system}
    or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  # Platform checksum (hex sha256) is extracted from the manifest automatically
  checksum = manifest.platforms.${gcsPlatform}.checksum;
in
stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${gcs}/${version}/${gcsPlatform}/claude";
    sha256 = checksum;
  };

  dontUnpack = true;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m 755 $src $out/bin/claude
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
