{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nani-translate-linux.homeManagerModules.default
  ];

  my.programs = {
    emacs.enable = true;
    niri.enable = true;
    swaylock.enable = true;
    noctalia.enable = true;
    vicinae.enable = true;
  };
  my.services.swayidle.enable = true;

  programs.naniTranslateLinux.enable = true;
  ext.xdg.enable = true;
  xdg.desktopEntries.find-my-phone = {
    name = "Find My Phone";
    comment = "Find your phone with your Google Account";
    exec = "${pkgs.xdg-utils}/bin/xdg-open https://myaccount.google.com/find-your-phone";
    icon = "smartphone";
    terminal = false;
    categories = [ "Utility" ];
    settings.Keywords = "Google;Find My Phone;Find Hub;Android;";
  };
  services.wallpaper.enable = true;

  gtk = {
    enable = true;
    gtk4.theme = null;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Inter";
      size = 11;
    };
  };
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # Unwrapped GTK 3 applications, including Tauri development builds, need
  # the file chooser schema on the desktop session search path.
  home.sessionVariables.XDG_DATA_DIRS = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";

  home.packages = with pkgs; [
    buzz
    file-roller
    mpvpaper
    pavucontrol
    rquickshare
    sushi
    swappy
    turbowarp-desktop
    wl-clipboard
    zenity
    zoom-us
  ];
}
