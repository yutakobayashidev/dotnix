_:

{
  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.my.programs.noctalia;
      codexbarUsagePlugin = pkgs.runCommand "noctalia-codexbar-usage-plugin" { } ''
        mkdir -p "$out"
        cp ${./plugins/codexbar-usage/plugin.toml} "$out/plugin.toml"
        substitute ${./plugins/codexbar-usage/usage.luau} "$out/usage.luau" \
          --replace-fail "@codexbarPath@" "${lib.getExe pkgs.codexbar-waybar}"
      '';
    in
    {
      options.my.programs.noctalia.enable = lib.mkEnableOption "Noctalia";

      config = lib.mkIf cfg.enable {
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
            dock.enabled = false;

            # Connect accounts through Settings → Calendar; credentials stay in Secret Service.
            calendar = {
              enabled = true;
              reminders = {
                enabled = true;
                use_event_reminders = true;
                default_lead_minutes = 10;
              };
            };

            bar.main = {
              margin_ends = 12;
              margin_edge = 8;
              thickness = 34;
              radius = 12;
              background_opacity = 0.95;
              widget_spacing = 6;
              padding = 12;
              position = "top";
              start = [
                "app-launcher"
                "dotnetrob/cat:cat"
                "yuta/codexbar-usage:usage"
                "media"
              ];
              center = [ "workspaces" ];
              end = [
                "tray"
                "notifications"
                "privacy"
                "network"
                "battery"
                "output-volume"
                "clock"
                "control-center"
              ];
            };

            plugins.enabled = [
              "yuta/codexbar-usage"
              "dotnetrob/cat"
            ];

            widget = {
              app-launcher = {
                type = "custom_button";
                glyph = "apps";
                actions.left = "vicinae toggle";
                tooltip = "Applications";
              };
              workspaces = {
                type = "workspaces";
                style = "focus_hint";
                show_labels = false;
                show_icons = false;
                hide_when_empty = true;
              };
              battery = {
                type = "battery";
                display_mode = "graphic";
              };
              media = {
                type = "media";
                hide_when_no_media = true;
                max_length = 180;
                title_scroll = "always";
              };
              output-volume = {
                type = "volume";
                device = "output";
                show_label = false;
              };
              clock = {
                type = "clock";
                format = "{:%m/%d %H:%M}";
                vertical_format = "{:%Y/%m/%d\n%H:%M}";
                tooltip_format = "{:%Y/%m/%d %H:%M (%a)}";
              };
              tray = {
                type = "tray";
                pinned = [ "org.fcitx.Fcitx5" ];
              };
            };

            shell = {
              corner_radius_scale = 1.0;
              font_family = "Inter";
              clipboard_enabled = false;
              launch_apps_as_systemd_services = true;
            };

            control_center.sidebar = "compact";
            control_center.shortcuts = [
              { type = "wifi"; }
              { type = "bluetooth"; }
              { type = "media"; }
              { type = "notification"; }
              { type = "nightlight"; }
              { type = "wallpaper"; }
            ];
          };
        };
      };
    };
}
