{ pkgs, ... }:

{
  home.packages = [ pkgs.fastfetch ];
  xdg.configFile."fastfetch/config.jsonc".source = ./config.jsonc;
}
