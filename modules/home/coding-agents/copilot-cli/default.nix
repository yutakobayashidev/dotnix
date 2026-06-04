{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.copilot-cli;
in
{
  options.my.programs.copilot-cli.enable = lib.mkEnableOption "Copilot CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.copilot-cli ];
  };
}
