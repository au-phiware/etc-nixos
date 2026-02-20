{
  description = "Chromium binary release";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { pkgs, ... }: {
        packages.default = (let
          specs = {
            aarch64-darwin = {
              arch = "mac-arm64";
              hash = "sha256-8FeYbXzMDoTVxeAaKe3F4SYRKDz2pirRj3BAF7gtCR8=";
              version = "143.0.7499.192";
            };
            x86_64-darwin = {
              arch = "mac-x64";
              hash = "sha256-YVUPCu7+lpKksITsBncif2fqoo08iJ/+dCwnoftHpm8=";
              version = "143.0.7499.192";
            };
          };
          spec = specs.${pkgs.stdenv.hostPlatform.system} or {
            arch = "";
            hash = "";
            version = "";
          };
        in pkgs.stdenv.mkDerivation rec {
          pname = "chromium";
          version = spec.version;
          src = pkgs.fetchzip {
            url =
              "https://storage.googleapis.com/chrome-for-testing-public/${spec.version}/${spec.arch}/chrome-headless-shell-${spec.arch}.zip";
            hash = spec.hash;
          };

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p "$out/bin" "$out/Applications"
            mv -t "$out/Applications/" "Chromium.app/"
            makeWrapper "$out/Applications/Chromium.app/Contents/MacOS/Chromium" "$out/bin/${pname}"
          '';

          meta = {
            description =
              "An open source web browser from Google (binary release)";
            downloadPage =
              "https://googlechromelabs.github.io/chrome-for-testing/";
            homepage = "https://www.chromium.org/Home/";
            license = pkgs.lib.licenses.bsd3;
            platforms = builtins.attrNames specs;
            mainProgram = pname;
            maintainers = with pkgs.lib.maintainers; [ lrworth ];
            hydraPlatforms = [ ];
            sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
          };
        });

      };
    };
}
