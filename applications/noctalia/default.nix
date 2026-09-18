{ lib, pkgs, ... }:

let
  codexbarUsagePlugin = pkgs.runCommand "noctalia-codexbar-usage-plugin" { } ''
    mkdir -p "$out"
    cp ${./plugins/codexbar-usage/plugin.toml} "$out/plugin.toml"
    substitute ${./plugins/codexbar-usage/usage.luau} "$out/usage.luau" \
      --replace-fail "@codexbarPath@" "${lib.getExe pkgs.codexbar-waybar}"
  '';
in
{
  home.packages = [ pkgs.networkmanagerapplet ];

  xdg.dataFile."noctalia/plugins/codexbar-usage" = {
    source = codexbarUsagePlugin;
    recursive = true;
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
        templates = {
          enable_builtin_templates = false;
          enable_community_templates = false;
        };
      };

      desktop_widgets.enabled = false;
      lockscreen.enabled = false;
      wallpaper.enabled = false;
      dock.enabled = false;

      bar.main = {
        margin_ends = 8;
        position = "top";
        start = [
          "app-launcher"
          "workspaces"
        ];
        center = [ "media" ];
        end = [
          "yuta/codexbar-usage:usage"
          "spacer"
          "notifications"
          "tray"
          "spacer"
          "network"
          "bluetooth"
          "battery"
          "input-volume"
          "output-volume"
          "privacy"
          "brightness"
          "cpu"
          "ram"
          "clock"
          "control-center"
        ];
      };

      plugins.enabled = [ "yuta/codexbar-usage" ];

      widget = {
        app-launcher = {
          type = "custom_button";
          glyph = "apps";
          actions.left = "vicinae toggle";
          tooltip = "Applications";
        };
        workspaces = {
          type = "workspaces";
          hide_when_empty = true;
        };
        media = {
          type = "media";
          hide_when_no_media = true;
          title_scroll = "always";
        };
        battery = {
          type = "battery";
          display_mode = "graphic";
        };
        brightness = {
          type = "brightness";
          show_label = false;
        };
        input-volume = {
          type = "volume";
          device = "input";
          show_label = false;
        };
        output-volume = {
          type = "volume";
          device = "output";
        };
        cpu = {
          type = "sysmon";
          stat = "cpu_usage";
        };
        ram = {
          type = "sysmon";
          stat = "ram_used";
        };
        clock = {
          type = "clock";
          format = "{:%Y/%m/%d %H:%M}";
          vertical_format = "{:%Y/%m/%d\n%H:%M}";
          tooltip_format = "{:%Y/%m/%d %H:%M (%a)}";
        };
        tray = {
          type = "tray";
          pinned = [ "org.fcitx.Fcitx5" ];
        };
      };

      shell = {
        corner_radius_scale = 0.2;
        clipboard_enabled = false;
        launch_apps_as_systemd_services = true;
      };

      control_center.shortcuts = [
        { type = "wifi"; }
        { type = "bluetooth"; }
        { type = "screen_recorder"; }
        { type = "notifications"; }
        { type = "nightlight"; }
      ];
    };
  };
}
