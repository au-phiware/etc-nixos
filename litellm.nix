{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.litellm;
  settingsFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ ];

  options = {
    services.litellm = {
      enable = mkEnableOption "LiteLLM server";
      
      package = mkOption {
        type = types.package;
        default = pkgs.python3Packages.litellm.overrideAttrs (old: {
          propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ 
            (with pkgs.python3Packages; litellm.optional-dependencies.proxy or []);
        });
        description = "The LiteLLM package to use.";
      };

      stateDir = mkOption {
        type = types.path;
        default = "/Users/${config.users.primaryUser or "Shared"}/Library/Application Support/litellm";
        example = "/Users/john/.local/share/litellm";
        description = "State directory of LiteLLM.";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "0.0.0.0";
        description = ''
          The host address which the LiteLLM server HTTP interface listens to.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 4000;
        example = 8080;
        description = ''
          Which port the LiteLLM server listens to.
        '';
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = settingsFormat.type;
          options = {
            model_list = mkOption {
              type = settingsFormat.type;
              description = ''
                List of supported models on the server, with model-specific configs.
              '';
              default = [ ];
            };
            
            router_settings = mkOption {
              type = settingsFormat.type;
              description = ''
                LiteLLM Router settings
              '';
              default = { };
            };

            litellm_settings = mkOption {
              type = settingsFormat.type;
              description = ''
                LiteLLM Module settings
              '';
              default = { };
            };

            general_settings = mkOption {
              type = settingsFormat.type;
              description = ''
                LiteLLM Server settings
              '';
              default = { };
            };

            environment_variables = mkOption {
              type = settingsFormat.type;
              description = ''
                Environment variables to pass to LiteLLM
              '';
              default = { };
            };
          };
        };
        default = { };
        description = ''
          Configuration for LiteLLM.
          See <https://docs.litellm.ai/docs/proxy/configs> for more.
        '';
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {
          SCARF_NO_ANALYTICS = "True";
          DO_NOT_TRACK = "True";
          ANONYMIZED_TELEMETRY = "False";
        };
        example = {
          NO_DOCS = "True";
        };
        description = ''
          Extra environment variables for LiteLLM.
          
          Be aware that these are only seen by the litellm server (launchd daemon),
          not normal invocations of the litellm CLI.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.litellm = {
      path = [ config.environment.systemPath ];

      script = let
        configFile = settingsFormat.generate "config.yaml" cfg.settings;
      in ''
        # Create state directory if it doesn't exist
        mkdir -p "${cfg.stateDir}"
        cd "${cfg.stateDir}"
        
        exec ${getExe cfg.package} --host "${cfg.host}" --port ${toString cfg.port} --config ${configFile}
      '';

      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/litellm.log";
        StandardErrorPath = "/tmp/litellm.error.log";
        EnvironmentVariables = cfg.environment;
      };
    };
  };
}
