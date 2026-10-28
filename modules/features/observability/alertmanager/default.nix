_: {
  flake.modules.nixos.alertmanager =
    { config, lib, ... }:
    let
      cfg = config.my.services.alertmanager;
      receiver = name: credential: resolved: {
        inherit name;
        discord_configs = [
          {
            webhook_url_file = "/run/credentials/alertmanager.service/${credential}";
            send_resolved = resolved;
            username = "dotnix monitoring";
            title = "[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}";
            message = ''
              {{ range .Alerts }}
              **{{ .Annotations.summary }}**
              {{ .Annotations.description }}
              {{ if .Labels.host }}Host: {{ .Labels.host }}{{ end }}{{ if .Labels.instance }} / {{ .Labels.instance }}{{ end }}{{ if .Labels.entity }} / {{ .Labels.entity }}{{ end }}
              {{ if .Annotations.dashboard_url }}{{ .Annotations.dashboard_url }}{{ end }}
              {{ end }}
            '';
          }
        ];
      };
    in
    {
      options.my.services.alertmanager = {
        enable = lib.mkEnableOption "Discord notifications for infrastructure and room alerts";
        notifications.enable = lib.mkEnableOption "Discord delivery after both webhook credential files are provisioned";
        infrastructureWebhookFile = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/monitoring-secrets/discord-infrastructure";
          description = "Runtime file containing the infrastructure Discord webhook URL; never put the URL in Nix.";
        };
        roomWebhookFile = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/monitoring-secrets/discord-room";
          description = "Runtime file containing the room Discord webhook URL.";
        };
      };
      config = lib.mkIf cfg.enable {
        services = {
          prometheus.alertmanager = {
            enable = true;
            listenAddress = "127.0.0.1";
            # One local instance; do not expose the gossip port either.
            extraFlags = [ "--cluster.listen-address=" ];
            configuration = {
              route = {
                receiver = if cfg.notifications.enable then "infrastructure" else "null";
                group_by = [
                  "alertname"
                  "host"
                  "instance"
                  "entity"
                ];
                group_wait = "30s";
                group_interval = "5m";
                repeat_interval = "24h";
                routes = lib.optionals cfg.notifications.enable [
                  {
                    matchers = [ ''category="room"'' ];
                    receiver = "room";
                    repeat_interval = "12h";
                    routes = [
                      {
                        matchers = [ ''kind="event"'' ];
                        receiver = "room-event";
                        group_wait = "10s";
                        repeat_interval = "120h";
                      }
                    ];
                  }
                  {
                    matchers = [ ''severity="critical"'' ];
                    receiver = "infrastructure";
                    group_wait = "10s";
                    repeat_interval = "1h";
                  }
                  {
                    matchers = [ ''severity="info"'' ];
                    receiver = "infrastructure-event";
                    repeat_interval = "120h";
                  }
                ];
              };
              receivers =
                lib.optional (!cfg.notifications.enable) { name = "null"; }
                ++ lib.optionals cfg.notifications.enable [
                  (receiver "infrastructure" "discord-infrastructure" true)
                  (receiver "infrastructure-event" "discord-infrastructure" false)
                  (receiver "room" "discord-room" true)
                  (receiver "room-event" "discord-room" false)
                ];
              inhibit_rules = [
                {
                  source_matchers = [ ''severity="critical"'' ];
                  target_matchers = [ ''severity="warning"'' ];
                  equal = [
                    "alertname"
                    "host"
                    "instance"
                    "entity"
                    "device"
                    "pool"
                    "uuid"
                  ];
                }
              ];
            };
          };
          vmalert.instances.main.settings."notifier.url" = [
            "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}"
          ];
          vmalert.instances.main.rules.groups = [
            {
              name = "alertmanager";
              rules = [
                {
                  alert = "AlertmanagerDown";
                  expr = ''up{job="alertmanager"} == 0 or absent(up{job="alertmanager"})'';
                  for = "5m";
                  labels = {
                    severity = "critical";
                    category = "infra";
                    host = config.networking.hostName;
                  };
                  annotations.summary = "Alertmanager is unavailable";
                  annotations.description = "Notifications cannot be delivered. Check Alertmanager and its Discord credential files. This alert remains visible in Grafana while delivery is unavailable.";
                }
                {
                  alert = "DiscordNotificationFailed";
                  expr = "increase(alertmanager_notifications_failed_total{integration=~\"discord.*\"}[15m]) > 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                    category = "infra";
                    host = config.networking.hostName;
                  };
                  annotations.summary = "Discord alert delivery is failing";
                  annotations.description = "Check Discord webhook credentials, connectivity, and Alertmanager logs. A broken receiver may not deliver this notification.";
                }
              ];
            }
          ];
          victoriametrics.prometheusConfig.scrape_configs = [
            {
              job_name = "alertmanager";
              static_configs = [
                {
                  targets = [ "127.0.0.1:${toString config.services.prometheus.alertmanager.port}" ];
                  labels.host = config.networking.hostName;
                }
              ];
            }
          ];
        };
        systemd.tmpfiles.rules = lib.optional cfg.notifications.enable "d /var/lib/monitoring-secrets 0700 root root -";
        systemd.services.alertmanager.serviceConfig.LoadCredential =
          lib.optionals cfg.notifications.enable
            [
              "discord-infrastructure:${cfg.infrastructureWebhookFile}"
              "discord-room:${cfg.roomWebhookFile}"
            ];
      };
    };
}
