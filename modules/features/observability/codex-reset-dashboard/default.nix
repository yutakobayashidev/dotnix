_:

{
  flake.modules.nixos.codex-reset-dashboard =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ ./notifications.nix ];

      config = lib.mkIf config.my.services.monitoring.enable {
        services.grafana = {
          declarativePlugins = [ pkgs.grafana-calendar-heatmap ];
          provision.dashboards.settings.providers = [
            {
              name = "codex-reset";
              options.path = ./dashboards;
              allowUiUpdates = false;
              disableDeletion = true;
            }
          ];
        };

        services.loki.configuration.limits_config = {
          # Keep a full year of the low-volume reset history without extending
          # the 30-day retention of unrelated service logs.
          retention_stream = [
            {
              selector = ''{job="codex-limit-auto-reset"}'';
              priority = 1;
              period = "9600h";
            }
          ];
          # Loki's default 30-day query limit would reject the annual calendar.
          max_query_length = "9600h";
        };
      };
    };
}
