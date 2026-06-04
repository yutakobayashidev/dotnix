{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.cursor-agent;
in
{
  options.my.programs.cursor-agent.enable = lib.mkEnableOption "Cursor Agent";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.cursor-agent ];
  };
}
