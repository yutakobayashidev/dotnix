{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.waza;
in
{
  options.my.programs.waza.enable = lib.mkEnableOption "waza";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.waza ];
  };
}
