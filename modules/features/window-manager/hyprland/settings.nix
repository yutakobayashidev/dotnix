{ lib, pkgs }:
let
  palette = import ../../../../lib/desktop-palette.nix;
  lua = lib.generators.mkLuaInline;
  bind = key: action: {
    _args = [
      key
      (lua action)
    ];
  };
  exec = key: command: bind key "hl.dsp.exec_cmd(${builtins.toJSON command})";
  directions = [
    "left"
    "right"
    "up"
    "down"
  ];
  workspaces = lib.range 1 10;
  key = n: if n == 10 then "0" else toString n;
in
{
  monitor = {
    output = "";
    mode = "preferred";
    position = "auto";
    scale = 1;
  };
  env = [
    {
      _args = [
        "XCURSOR_SIZE"
        "24"
      ];
    }
    {
      _args = [
        "HYPRCURSOR_SIZE"
        "24"
      ];
    }
  ];
  on._args = [
    "hyprland.start"
    (lua ''
      function()
            hl.exec_cmd("fcitx5 -d")
            hl.exec_cmd("${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
          end'')
  ];

  # Restore the former dwindle layout with the shared desktop palette.
  config = {
    general = {
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
      col.active_border = "#${palette.mauve}";
      col.inactive_border = "#${palette.surface1}";
      layout = "dwindle";
    };
    decoration = {
      rounding = 10;
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
      };
    };
    dwindle.preserve_split = true;
    input = {
      kb_layout = "us";
      follow_mouse = 1;
    };
  };

  bind = [
    (exec "SUPER + Q" "ghostty")
    (bind "SUPER + C" "hl.dsp.window.close()")
    (exec "SUPER + E" "nautilus")
    (exec "SUPER + R" "vicinae toggle")
    (exec "SUPER + V" "vicinae vicinae://launch/clipboard/history?toggle=true")
    (exec "SUPER + L" "${pkgs.systemd}/bin/loginctl lock-session")
    (bind "SUPER + SHIFT + M" "hl.dsp.exit()")
    (bind "SUPER + SHIFT + F" ''hl.dsp.window.float({ action = "toggle" })'')
    (bind "SUPER + J" ''hl.dsp.layout("togglesplit")'')
    (bind "SUPER + S" ''hl.dsp.workspace.toggle_special("magic")'')
    (bind "SUPER + CTRL + S" ''hl.dsp.window.move({ workspace = "special:magic" })'')
    (bind "SUPER + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
    (bind "SUPER + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')
    {
      _args = [
        "SUPER + mouse:272"
        (lua "hl.dsp.window.drag()")
        { mouse = true; }
      ];
    }
    {
      _args = [
        "SUPER + mouse:273"
        (lua "hl.dsp.window.resize()")
        { mouse = true; }
      ];
    }
    (exec "SUPER + bracketright" "${pkgs.grimblast}/bin/grimblast copy output")
    (exec "SUPER + SHIFT + bracketright" "${pkgs.grimblast}/bin/grimblast copy active")
    (exec "SUPER + SHIFT + S" "${pkgs.grimblast}/bin/grimblast copy area")
  ]
  ++ map (
    direction: bind "SUPER + ${direction}" ''hl.dsp.focus({ direction = "${direction}" })''
  ) directions
  ++ map (n: bind "SUPER + ${key n}" "hl.dsp.focus({ workspace = ${toString n} })") workspaces
  ++ map (
    n: bind "SUPER + SHIFT + ${key n}" "hl.dsp.window.move({ workspace = ${toString n} })"
  ) workspaces
  ++
    map
      (spec: {
        _args = [
          spec.key
          (lua "hl.dsp.exec_cmd(${builtins.toJSON spec.command})")
          {
            locked = true;
            repeating = true;
          }
        ];
      })
      [
        {
          key = "XF86AudioRaiseVolume";
          command = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
        }
        {
          key = "XF86AudioLowerVolume";
          command = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        }
        {
          key = "XF86AudioMute";
          command = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        }
        {
          key = "XF86AudioNext";
          command = "${pkgs.playerctl}/bin/playerctl next";
        }
        {
          key = "XF86AudioPlay";
          command = "${pkgs.playerctl}/bin/playerctl play-pause";
        }
        {
          key = "XF86AudioPrev";
          command = "${pkgs.playerctl}/bin/playerctl previous";
        }
      ];
}
