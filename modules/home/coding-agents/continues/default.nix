{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.continues;
in
{
  options.my.programs.continues.enable = lib.mkEnableOption "continues";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.continues ];
  };
}
