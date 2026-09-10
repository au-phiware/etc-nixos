{
  lib,
  stdenv,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  autoPatchelfHook,
}:

let
  version = "1.0.83";

  # The @github/copilot tarball is now only a loader that spawns a
  # native binary from a per-platform optional dependency, so fetch that
  # platform package directly.
  sources = {
    aarch64-darwin = {
      target = "darwin-arm64";
      hash = "sha256-fJwm9hBG3veGflsPLzod5smcyyWSWzpHTGIr0+3jzd4=";
    };
    x86_64-darwin = {
      target = "darwin-x64";
      hash = "sha256-sd9bWv+Ws4murflKjcoyuL9IJaxtTJ1P/Ymq7A//NY8=";
    };
    aarch64-linux = {
      target = "linux-arm64";
      hash = "sha256-hJAOUj8jWveEUCL5X9kwMJc2KS72UIxujBV6jF8VJNs=";
    };
    x86_64-linux = {
      target = "linux-x64";
      hash = "sha256-N/BxJeFpWHg8cRSafqJE0ueOeU91BsqJ3c2eXAz4mRM=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  source =
    sources.${system}
      or (throw "github-copilot-cli: no binary published for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "github-copilot-cli";
  version = "${version}";

  src = fetchzip {
    url = "https://registry.npmjs.org/@github/copilot-${source.target}/-/copilot-${source.target}-${version}.tgz";
    inherit (source) hash;
  };

  nativeBuildInputs = [
    makeWrapper
  ] ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;

  buildInputs = lib.optional stdenvNoCC.hostPlatform.isLinux stdenv.cc.cc.lib;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/copilot
    cp -r . $out/libexec/copilot/

    makeWrapper $out/libexec/copilot/copilot $out/bin/copilot

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
    platforms = lib.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
