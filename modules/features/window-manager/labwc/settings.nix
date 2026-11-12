{ lib, pkgs }:
let
  bind = key: action: {
    "@key" = key;
    inherit action;
  };
  execute =
    key: command:
    bind key {
      "@name" = "Execute";
      "@command" = command;
    };
in
{
  core.gap = 10;
  desktops."@number" = 4;
  keyboard = {
    default = true;
    keybind =
      (lib.concatMap (n: [
        (bind "W-${toString n}" {
          "@name" = "GoToDesktop";
          "@to" = toString n;
        })
        (bind "W-S-${toString n}" {
          "@name" = "SendToDesktop";
          "@to" = toString n;
        })
      ]) (lib.range 1 4))
      ++ [
        (execute "W-Return" "ghostty")
        (execute "W-q" "ghostty")
        (execute "W-e" "nautilus --new-window")
        (execute "W-d" "vicinae toggle")
        (execute "W-v" "vicinae vicinae://launch/clipboard/history?toggle=true")
        (execute "W-space" "${pkgs.procps}/bin/pkill -USR2 -f bin/handy")
        (execute "W-C-space" "${pkgs.procps}/bin/pkill -USR1 -f bin/handy")
        (execute "W-l" "${pkgs.systemd}/bin/loginctl lock-session")
        (execute "W-s" "noctalia msg panel-toggle control-center")
        (execute "W-comma" "noctalia msg settings-toggle")
        (execute "W-Escape" "noctalia msg panel-toggle session")
        (bind "W-c" { "@name" = "Close"; })
        (bind "W-f" { "@name" = "ToggleMaximize"; })
        (bind "W-S-e" { "@name" = "Exit"; })
        (execute "XF86AudioRaiseVolume" "noctalia msg volume-up")
        (execute "XF86AudioLowerVolume" "noctalia msg volume-down")
        (execute "XF86AudioMute" "noctalia msg volume-mute")
        (execute "XF86AudioMicMute" "noctalia msg mic-mute")
        (execute "XF86MonBrightnessUp" "noctalia msg brightness-up")
        (execute "XF86MonBrightnessDown" "noctalia msg brightness-down")
      ];
  };
  mouse.default = true;
}
