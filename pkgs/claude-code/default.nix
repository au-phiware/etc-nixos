{
  lib,
  stdenv,
  fetchurl,
}:

let
  # See DOWNLOAD_BASE_URL in https://claude.ai/install.sh
  dbu = "https://downloads.claude.ai/claude-code-releases";

  version = "2.1.266";

  # hash when bumping.
  #   nix-prefetch-url "${dbu}/$(curl -fsSL ${dbu}/latest)/manifest.json"
  manifest = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl {
        url = "${dbu}/${version}/manifest.json";
        sha256 = "1r2pahzvsxcyakplxx8h6d9ra51wq613082iicinr6z8rrbb8di7";
      }
    )
  );

  nixPlatformToGcs = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  gcsPlatform =
    nixPlatformToGcs.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  # Platform checksum (hex sha256) is extracted from the manifest automatically
  checksum = manifest.platforms.${gcsPlatform}.checksum;
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${dbu}/${version}/${gcsPlatform}/claude";
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
