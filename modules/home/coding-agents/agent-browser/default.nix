{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.agent-browser;
in
{
  options.my.programs.agent-browser.enable = lib.mkEnableOption "agent-browser";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.agent-browser ];
  };
}
