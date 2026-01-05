{ config, pkgs, ... }:

{
  programs.hyprpanel = {
    enable = true;
    settings = {
      bar.launcher.autoDetectIcon = true;
      layout = {
        "bar.layouts" = {
          "0" = {
            left = [ "dashboard" "workspaces" ];
            middle = [ "media" ];
            right = [ "volume" "clock" "systray" "notifications" ];
          };
        };
      };
      theme.font = {
        name = "Noto Sans CJK JP";
        size = "14px";
      };
    };
  };
}
