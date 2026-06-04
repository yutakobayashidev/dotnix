{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.spec-kit;
in
{
  options.my.programs.spec-kit.enable = lib.mkEnableOption "spec-kit";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.spec-kit ];
  };
}
