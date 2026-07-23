{ pkgs, ... }:

{
  services.swaync.enable = true;

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 40;
        spacing = 6;
        margin-top = 6;
        margin-left = 8;
        margin-right = 8;

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
          "network"
          "bluetooth"
          "battery"
          "custom/codexbar"
          "cpu"
          "memory"
          "clock"
          "tray"
          "custom/notification"
          "custom/power"
        ];

        # カスタムランチャー
        "custom/launcher" = {
          format = " ";
          on-click = "vicinae toggle";
          tooltip = false;
        };

        # Polycat (CPU アニメーション)
        "custom/polycat" = {
          exec = "polycat";
          tooltip = false;
        };

        # Codex usage
        "custom/codexbar" = {
          exec = "codexbar";
          return-type = "json";
          interval = 300;
          signal = 12;
          tooltip = true;
          on-click = "xdg-open https://chatgpt.com/codex/settings/usage";
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
          format = "BT {status}";
          format-connected = "BT {device_alias}";
          format-connected-battery = "BT {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        # ネットワーク
        "network" = {
          format-wifi = "Wi-Fi {signalStrength}%";
          format-ethernet = "Ethernet";
          format-disconnected = "Offline";
          tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}";
          tooltip-format-ethernet = "{ifname}\n{ipaddr}";
          tooltip-format-disconnected = "Disconnected";
          on-click = "nm-connection-editor";
        };

        # バッテリー
        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "BAT {capacity}%";
          format-charging = "AC {capacity}%";
          format-plugged = "AC {capacity}%";
          tooltip-format = "{timeTo}\nPower: {power:.1f} W";
        };

        # システムモニター
        "cpu" = {
          format = "CPU {usage}%";
          interval = 2;
          tooltip = false;
        };

        "memory" = {
          format = "MEM {percentage}%";
          interval = 5;
          tooltip-format = "{used:0.1f} GiB / {total:0.1f} GiB";
        };

        # 時計
        "clock" = {
          format = "TIME {:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M:%S}";
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

        # 電源メニュー
        "custom/power" = {
          format = "Power";
          tooltip = false;
          on-click = "wlogout";
        };
      };
    };

    style = ''
      * {
        border: none;
        font-family: "Noto Sans CJK JP", "Font Awesome 6 Free";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: transparent;
        color: #cad3f5;
      }

      #workspaces {
        padding: 3px;
        background-color: rgba(36, 39, 58, 0.88);
        border: 1px solid rgba(183, 189, 248, 0.18);
        border-radius: 12px;
      }

      #workspaces button {
        padding: 0 9px;
        color: #b8c0e0;
        background-color: transparent;
        border-radius: 9px;
        transition: background-color 150ms ease, color 150ms ease;
      }

      #workspaces button.active {
        background-color: #f5bde6;
        color: #181926;
      }

      #workspaces button:hover {
        background-color: rgba(183, 189, 248, 0.2);
      }

      #custom-launcher,
      #custom-polycat,
      #mpris,
      #custom-codexbar,
      #pulseaudio,
      #network,
      #bluetooth,
      #battery,
      #cpu,
      #memory,
      #clock,
      #tray,
      #custom-notification,
      #custom-power {
        padding: 0 10px;
        background-color: rgba(36, 39, 58, 0.88);
        border: 1px solid rgba(183, 189, 248, 0.18);
        border-radius: 12px;
      }

      #mpris {
        color: #b7bdf8;
      }

      #cpu,
      #memory {
        color: #8bd5ca;
      }

      #pulseaudio.muted {
        color: #f38ba8;
      }

      #bluetooth.connected {
        color: #89b4fa;
      }

      #network.disconnected,
      #battery.warning {
        color: #f9e2af;
      }

      #battery.critical {
        color: #f38ba8;
      }

      #battery.charging,
      #battery.plugged {
        color: #a6e3a1;
      }

      #custom-power {
        color: #f38ba8;
      }

      #custom-launcher {
        color: #f5bde6;
        font-size: 20px;
      }

      tooltip {
        background-color: rgba(36, 39, 58, 0.96);
        border: 1px solid #b7bdf8;
        border-radius: 12px;
      }

      tooltip label {
        color: #cdd6f4;
      }
    '';
  };

  # 必要なパッケージ
  home.packages = with pkgs; [
    codexbar-waybar
    font-awesome
    networkmanagerapplet
    wlogout
  ];
}
