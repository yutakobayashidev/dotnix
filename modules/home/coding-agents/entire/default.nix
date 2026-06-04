{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.entire;
in
{
  options.my.programs.entire.enable = lib.mkEnableOption "entire";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.entire ];
  };
}
