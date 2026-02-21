{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    intune.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Whether to enable Microsoft InTune.";
      example = false;
    };
  };

  config = lib.mkIf config.intune.enable {
    services.intune.enable = true;
  };
}
