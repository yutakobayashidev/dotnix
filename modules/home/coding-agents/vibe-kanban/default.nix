{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.vibe-kanban;
in
{
  options.my.programs.vibe-kanban.enable = lib.mkEnableOption "vibe-kanban";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.vibe-kanban ];
  };
}
