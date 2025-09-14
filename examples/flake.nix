{
  description = "CBA Development Environments";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Node.js version that works well with both Nest.js and SST
        nodejs = pkgs.nodejs_22;
        corepack = pkgs.corepack_22;

        # Development shell dependencies
        shellDependencies = with pkgs; [
          nodejs
          corepack
          awscli2  # Required for SST deployments
          docker   # For local development
          git
          util-linux # For uuidgen

          # Development tools
          nixpkgs-fmt
          nodePackages.typescript
          nodePackages.typescript-language-server
          nest-cli
          bun
          dotenv-cli
          gnupatch
        ];

      in
      {
        devShells.default = pkgs.mkShell rec {
          buildInputs = shellDependencies;

          ARTIFACTORY_PAAS_TOKEN = "changeit";
          CECK_ARCH = "amd64-darwin";

          AWS_DEFAULT_REGION = "ap-southeast-2";
          AWS_REGION="ap-southeast-2";
          AWS_SSO_PROFILE = "sso_payt-npd-payments_paas";
          AWS_PROFILE="admin_payt-npd-payments_paas";
          AWS_SDK_LOAD_CONFIG = "1";
          POWERTOOLS_DEV = true;
          POWERTOOLS_LOGGER_LOG_EVENT = true;
          POWERTOOLS_LOG_LEVEL = "DEBUG";
          NO_BUN = "1";
          SST_STAGE = "lawsonco";

          CDK_BOOTSTRAP_STACK_NAME = "changeit";

          shellHook = ''
            # Run all the NPM installed tools, for better or for worse
            export PATH="$PWD/node_modules/.bin:$PATH"

            # Ensure npm uses nodejs from nix
            export npm_config_nodedir="${nodejs}"

            ${pkgs.awscli2}/bin/aws --profile="${AWS_SSO_PROFILE}" sso login

            ~/bin/check-for-paas-changes
            echo "🚀 Welcome to CBA development environment!"
          '';
        };

        # Formatter configuration
        formatter = pkgs.nixpkgs-fmt;

        # Add custom packages if needed
        packages = {
          # Example of creating a custom package
          # my-app = pkgs.callPackage ./nix/my-app.nix {};
        };
      });
}

