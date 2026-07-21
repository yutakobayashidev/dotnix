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

  # Unwrapped GTK 3 applications, including Tauri development builds, need
  # the file chooser schema on the desktop session search path.
  home.sessionVariables.XDG_DATA_DIRS = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";

  home.packages = with pkgs; [
    file-roller
    mpvpaper
    pavucontrol
    sushi
    swappy
    wl-clipboard
    zenity
    zoom-us
  ];
}
