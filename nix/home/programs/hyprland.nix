{ pkgs, ... }:

{
  "$terminal" = "ghostty";
  "$fileManager" = "dolphin";
  "$menu" = "rofi -show drun";
  "$mainMod" = "SUPER";

  monitor = ",preferred,auto,1.5";

  exec-once = [
    "swww-daemon && swww img ~/wallpapers/wp13990714.png --transition-type fade"
    "fcitx5 -d"
    "hyprpanel"
    "spotify"
    "wl-paste --watch cliphist store"
  ];

  env = [
    "XCURSOR_SIZE,24"
    "HYPRCURSOR_SIZE,24"
  ];

  general = {
    gaps_in = 5;
    gaps_out = 20;
    border_size = 2;
    "col.active_border" = "rgba(f5bde6ee) rgba(c6a0f6ee) 45deg";
    "col.inactive_border" = "rgba(5b6078aa)";
    resize_on_border = false;
    allow_tearing = false;
    layout = "dwindle";
  };

  decoration = {
    rounding = 10;
    rounding_power = 2;
    active_opacity = 1.0;
    inactive_opacity = 1.0;

    shadow = {
      enabled = true;
      range = 4;
      render_power = 3;
      color = "rgba(1a1a1aee)";
    };

    blur = {
      enabled = true;
      size = 3;
      passes = 1;
      vibrancy = 0.1696;
    };
  };

  animations = {
    enabled = true;
    bezier = [
      "easeOutQuint, 0.23, 1, 0.32, 1"
      "easeInOutCubic, 0.65, 0.05, 0.36, 1"
      "linear, 0, 0, 1, 1"
      "almostLinear, 0.5, 0.5, 0.75, 1"
      "quick, 0.15, 0, 0.1, 1"
    ];
    animation = [
      "global, 1, 10, default"
      "border, 1, 5.39, easeOutQuint"
      "windows, 1, 4.79, easeOutQuint"
      "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
      "windowsOut, 1, 1.49, linear, popin 87%"
      "fadeIn, 1, 1.73, almostLinear"
      "fadeOut, 1, 1.46, almostLinear"
      "fade, 1, 3.03, quick"
      "layers, 1, 3.81, easeOutQuint"
      "layersIn, 1, 4, easeOutQuint, fade"
      "layersOut, 1, 1.5, linear, fade"
      "fadeLayersIn, 1, 1.79, almostLinear"
      "fadeLayersOut, 1, 1.39, almostLinear"
      "workspaces, 1, 1.94, almostLinear, fade"
      "workspacesIn, 1, 1.21, almostLinear, fade"
      "workspacesOut, 1, 1.94, almostLinear, fade"
      "zoomFactor, 1, 7, quick"
    ];
  };

  dwindle = {
    pseudotile = true;
    preserve_split = true;
  };

  master = {
    new_status = "master";
  };

  misc = {
    force_default_wallpaper = -1;
    disable_hyprland_logo = false;
  };

  input = {
    kb_layout = "us";
    follow_mouse = 1;
    sensitivity = 0;
    touchpad = {
      natural_scroll = false;
    };
  };

  device = {
    name = "epic-mouse-v1";
    sensitivity = -0.5;
  };

  bind = [
    "$mainMod, Q, exec, $terminal"
    "$mainMod, C, killactive,"
    "$mainMod, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
    "$mainMod, E, exec, $fileManager"
    "$mainMod SHIFT, F, togglefloating,"
    "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
    "$mainMod, R, exec, $menu"
    "$mainMod, P, pseudo,"
    "$mainMod, J, togglesplit,"

    # Swap windows
    "$mainMod, left, swapwindow, l"
    "$mainMod, right, swapwindow, r"
    "$mainMod, up, swapwindow, u"
    "$mainMod, down, swapwindow, d"

    # Switch workspaces
    "$mainMod, 1, workspace, 1"
    "$mainMod, 2, workspace, 2"
    "$mainMod, 3, workspace, 3"
    "$mainMod, 4, workspace, 4"
    "$mainMod, 5, workspace, 5"
    "$mainMod, 6, workspace, 6"
    "$mainMod, 7, workspace, 7"
    "$mainMod, 8, workspace, 8"
    "$mainMod, 9, workspace, 9"
    "$mainMod, 0, workspace, 10"

    # Move to workspace
    "$mainMod SHIFT, 1, movetoworkspace, 1"
    "$mainMod SHIFT, 2, movetoworkspace, 2"
    "$mainMod SHIFT, 3, movetoworkspace, 3"
    "$mainMod SHIFT, 4, movetoworkspace, 4"
    "$mainMod SHIFT, 5, movetoworkspace, 5"
    "$mainMod SHIFT, 6, movetoworkspace, 6"
    "$mainMod SHIFT, 7, movetoworkspace, 7"
    "$mainMod SHIFT, 8, movetoworkspace, 8"
    "$mainMod SHIFT, 9, movetoworkspace, 9"
    "$mainMod SHIFT, 0, movetoworkspace, 10"

    # Special workspace
    "$mainMod, S, togglespecialworkspace, magic"
    "$mainMod SHIFT, S, movetoworkspace, special:magic"

    # Scroll workspaces
    "$mainMod, mouse_down, workspace, e+1"
    "$mainMod, mouse_up, workspace, e-1"

    # Screenshot (clipboard only)
    "$mainMod, bracketright, exec, grimblast copy output"
    "$mainMod SHIFT, bracketright, exec, grimblast copy active"
    "$mainMod SHIFT, s, exec, grimblast copy area"
  ];

  bindm = [
    "$mainMod, mouse:272, movewindow"
    "$mainMod, mouse:273, resizewindow"
  ];

  binde = [
    "$mainMod CTRL, left, resizeactive, -50 0"
    "$mainMod CTRL, right, resizeactive, 50 0"
    "$mainMod CTRL, up, resizeactive, 0 -50"
    "$mainMod CTRL, down, resizeactive, 0 50"
  ];

  bindel = [
    ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
    ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
    ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
  ];

  bindl = [
    ",XF86AudioNext, exec, playerctl next"
    ",XF86AudioPause, exec, playerctl play-pause"
    ",XF86AudioPlay, exec, playerctl play-pause"
    ",XF86AudioPrev, exec, playerctl previous"
  ];

}
