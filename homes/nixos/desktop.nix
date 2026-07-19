{ pkgs, ... }:

{
  imports = [
    ../../applications/niri
    ../../applications/waybar
    ../../applications/swayidle
    ../../applications/swaylock
    ../../applications/zaproxy
  ];

  my.programs = {
    emacs.enable = true;
    vicinae.enable = true;
  };
  services.wallpaper.enable = true;

  home.packages = with pkgs; [
    grimblast
    swappy
    wl-clipboard
    zenity
  ];
}
