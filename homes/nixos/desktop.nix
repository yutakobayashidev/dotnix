{ pkgs, ... }:

{
  my.programs.vicinae.enable = true;

  imports = [
    ../../applications/niri
    ../../applications/waybar
    ../../applications/swayidle
    ../../applications/swaylock
    ../../applications/zaproxy
  ];

  home.packages = with pkgs; [
    grimblast
    swappy
    awww
    wl-clipboard
    zenity
  ];
}
