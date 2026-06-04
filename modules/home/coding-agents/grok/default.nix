{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.grok;
in
{
  options.my.programs.grok.enable = lib.mkEnableOption "Grok Build";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.grok ];
  };
}
