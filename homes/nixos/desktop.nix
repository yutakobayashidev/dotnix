{ inputs, pkgs, ... }:

{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
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
  programs.codexDesktopLinux = {
    enable = true;
    package = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
    cliPackage = pkgs.llm-agents.codex;
  };
  ext.xdg.enable = true;
  services.wallpaper.enable = true;

  # Unwrapped GTK 3 applications, including Tauri development builds, need
  # the file chooser schema on the desktop session search path.
  home.sessionVariables.XDG_DATA_DIRS = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";

  home.packages = with pkgs; [
    buzz
    file-roller
    mpvpaper
    pavucontrol
    rquickshare
    screenpipe-app
    screenpipe-cli
    sushi
    swappy
    turbowarp-desktop
    wl-clipboard
    zenity
    zoom-us
  ];
}
