{ pkgs, ... }:

{
  my.programs.vicinae.enable = true;
  services.wallpaper.enable = true;

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
    wl-clipboard
    zenity
  ];
}
