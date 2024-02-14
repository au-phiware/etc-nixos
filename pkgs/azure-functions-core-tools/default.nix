{
  stdenv,
  lib,
  config,
  fetchurl,
  unzip,
  makeWrapper,
  icu,
  libunwind,
  curl,
  zlib,
  libuuid,
  openssl,
}: let
  platforms = {
    "x86_64-linux" = {
      platformStr = "linux-x64";
      hash = "sha256-08zp3UJHnMw858lRi4p+1vOsEmvRlz3AoC+HdOSScRc=";
    };
  };

  platformInfo = builtins.getAttr stdenv.hostPlatform.system platforms;
in
  stdenv.mkDerivation rec {
    pname = "azure-functions-core-tools";
    version = "4.0.5455";

    src = fetchurl {
      url = "https://github.com/Azure/${pname}/releases/download/${version}/Azure.Functions.Cli.${platformInfo.platformStr}.${version}.zip";
      inherit (platformInfo) hash;
    };

    nativeBuildInputs = [
      unzip
      makeWrapper
      icu
      libunwind
      curl
      zlib
    ];

    libPath = lib.makeLibraryPath [
      libunwind
      libuuid
      stdenv.cc.cc
      curl
      zlib
      icu
      openssl
    ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase =
      ''
        mkdir -p $out/bin
        cp -prd . $out/bin/azure-functions-core-tools
        chmod +x $out/bin/azure-functions-core-tools/{func,gozip}
      ''
      + lib.optionalString stdenv.isLinux ''
        patchelf \
          --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath "${libPath}" "$out/bin/azure-functions-core-tools/func"
        find $out/bin/azure-functions-core-tools -type f -name "*.so" -exec patchelf --set-rpath "${libPath}" {} \;
        wrapProgram "$out/bin/azure-functions-core-tools/func" --prefix LD_LIBRARY_PATH : ${libPath}
      ''
      + ''
        ln -s $out/bin/{azure-functions-core-tools,}/func
        ln -s $out/bin/{azure-functions-core-tools,}/gozip
      '';
    dontStrip = true; # Causes rpath patching to break if not set

    meta = with lib; {
      homepage = "https://github.com/Azure/azure-functions-core-tools";
      description = "Command line tools for Azure Functions";
      sourceProvenance = with sourceTypes; [
        binaryBytecode
        binaryNativeCode
      ];
      license = licenses.mit;
      maintainers = with maintainers; [ mdarocha ];
      platforms = ["x86_64-linux" "aarch64-darwin" "x86_64-darwin"];
    };
  }
