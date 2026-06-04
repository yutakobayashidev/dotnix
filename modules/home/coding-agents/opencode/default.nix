{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.my.programs.opencode;

  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    logLevel = "DEBUG";
  };
in
{
  options.my.programs.opencode.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf cfg.enable {
    # OpenCode package
    home.packages = lib.mkAfter [ pkgs.llm-agents.opencode ];

    # Generate opencode.json
    xdg.configFile."opencode/opencode.json" = {
      text = opencodeConfig;
    };
  };
}
