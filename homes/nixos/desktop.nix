{ pkgs, ... }:

{
  imports = [
    ../../applications/niri
    ../../applications/waybar
    ../../applications/swayidle
    ../../applications/swaylock
    ../../applications/zaproxy
  ];

  home.packages = with pkgs; [
    cliphist
    grimblast
    rofi
    swappy
    awww
    wl-clipboard
    zenity
  ];
}
