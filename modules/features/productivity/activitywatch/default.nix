_:

{
  flake.modules.homeManager.activitywatch =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.services.activitywatch.enable =
        lib.mkEnableOption "local ActivityWatch recording on Wayland";

      config = lib.mkIf config.my.services.activitywatch.enable {
        services.activitywatch = {
          enable = true;
          settings = {
            address = "127.0.0.1";
            port = 5600;
          };
          watchers.aw-watcher-window-wayland.package = pkgs.aw-watcher-window-wayland;
        };

        # Wait for the compositor and its exported Wayland environment.
        systemd.user.targets.activitywatch = {
          Unit = {
            Requires = lib.mkForce [ ];
            After = lib.mkForce [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
        };
        systemd.user.services.activitywatch-watcher-aw-watcher-window-wayland.Service = {
          Restart = "on-failure";
          RestartSec = 5;
        };

        xdg.desktopEntries.activitywatch-dashboard = {
          name = "ActivityWatch";
          comment = "View local application, browser and AFK history";
          exec = "${pkgs.xdg-utils}/bin/xdg-open http://127.0.0.1:5600";
          terminal = false;
          categories = [ "Utility" ];
        };

        programs.firefox.policies.ExtensionSettings = lib.mkIf config.programs.firefox.enable {
          "{ef87d84c-2127-493f-b952-5b4e744245bc}" = {
            installation_mode = "normal_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/aw-watcher-web/latest.xpi";
          };
        };
      };
    };
}
