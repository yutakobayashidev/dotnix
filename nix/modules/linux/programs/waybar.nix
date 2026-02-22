{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 40;
        spacing = 4;

        modules-left = [
          "custom/launcher"
          "niri/workspaces"
        ];

        modules-center = [
          "custom/polycat"
          "mpris"
        ];

        modules-right = [
          "pulseaudio"
          "bluetooth"
          "clock"
          "tray"
          "custom/notification"
        ];

        # カスタムランチャー
        "custom/launcher" = {
          format = " ";
          on-click = "rofi -show drun";
          tooltip = false;
        };

        # Polycat (CPU アニメーション)
        "custom/polycat" = {
          exec = "polycat";
          return-type = "";
          tooltip = false;
        };

        # niri ワークスペース
        "niri/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        # メディア（MPRIS）
        "mpris" = {
          format = "{player_icon} {title} - {artist}";
          format-paused = "{status_icon} {title} - {artist}";
          player-icons = {
            default = "▶";
            spotify = "";
          };
          status-icons = {
            paused = "⏸";
          };
          max-length = 50;
        };

        # オーディオ
        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}%";
          format-muted = " {volume}%";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          tooltip-format = "{desc}";
        };

        # Bluetooth
        "bluetooth" = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        # 時計
        "clock" = {
          format = " {:%H:%M}";
          format-alt = " {:%Y-%m-%d %H:%M:%S}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
        };

        # システムトレイ
        "tray" = {
          spacing = 10;
        };

        # 通知
        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "Noto Sans CJK JP", "Font Awesome 6 Free";
        font-size: 14px;
        min-height: 0;
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.9);
        color: #cdd6f4;
      }

      #workspaces button {
        padding: 0 10px;
        color: #cdd6f4;
        background-color: transparent;
      }

      #workspaces button.active {
        background-color: rgba(245, 189, 230, 0.3);
        color: #f5bde6;
      }

      #workspaces button:hover {
        background-color: rgba(245, 189, 230, 0.1);
      }

      #custom-launcher,
      #mpris,
      #pulseaudio,
      #bluetooth,
      #clock,
      #tray,
      #custom-notification {
        padding: 0 10px;
        margin: 0 2px;
      }

      #pulseaudio.muted {
        color: #f38ba8;
      }

      #bluetooth.connected {
        color: #89b4fa;
      }

      #custom-launcher {
        color: #f5bde6;
        font-size: 20px;
      }

      tooltip {
        background-color: rgba(30, 30, 46, 0.95);
        border: 2px solid #f5bde6;
        border-radius: 10px;
      }

      tooltip label {
        color: #cdd6f4;
      }
    '';
  };

  # 必要なパッケージ
  home.packages = with pkgs; [
    font-awesome
    swaynotificationcenter
  ];
}
