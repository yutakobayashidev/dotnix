_: {
  flake.modules.nixos.activitylog =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.activitylog;
      domain = "home.yutakobayashi.com";
      # activitylog emits cumulative counters with OTel units, so the default
      # suffix translation (activity.time + s -> activity_time_seconds_total)
      # matches the dashboard PromQL. The coding-agent pipeline deliberately
      # disables this because its metrics already carry final Prometheus names.
      alloyConfig = ''
        otelcol.receiver.otlp "activitylog" {
          http { endpoint = "127.0.0.1:${toString cfg.otlpPort}" }
          output {
            metrics = [otelcol.processor.memory_limiter.activitylog.input]
            logs    = [otelcol.processor.memory_limiter.activitylog.input]
            traces  = [otelcol.processor.memory_limiter.activitylog.input]
          }
        }

        otelcol.processor.memory_limiter "activitylog" {
          check_interval = "1s"
          limit          = "512MiB"
          spike_limit    = "128MiB"
          output {
            metrics = [otelcol.exporter.prometheus.activitylog.input]
            logs    = [otelcol.exporter.otlphttp.activitylog_loki.input]
            traces  = [otelcol.exporter.otlp.activitylog_tempo.input]
          }
        }

        otelcol.exporter.prometheus "activitylog" {
          add_metric_suffixes              = true
          resource_to_telemetry_conversion = true
          forward_to = [prometheus.remote_write.activitylog.receiver]
        }

        prometheus.remote_write "activitylog" {
          endpoint { url = "http://127.0.0.1:8428/api/v1/write" }
        }

        otelcol.exporter.otlphttp "activitylog_loki" {
          client { endpoint = "http://127.0.0.1:3100/otlp" }
        }

        otelcol.exporter.otlp "activitylog_tempo" {
          client {
            endpoint = "127.0.0.1:14317"
            tls { insecure = true }
          }
        }
      '';
    in
    {
      options.my.services.activitylog = {
        enable = lib.mkEnableOption "activitylog OTLP ingress (Android/desktop activity → VictoriaMetrics/Loki/Tempo)";
        otlpHostname = lib.mkOption {
          type = lib.types.str;
          default = "otlp.${domain}";
          description = "Hostname for the OTLP endpoint. Tailnet-resolved, served by Traefik.";
        };
        otlpPort = lib.mkOption {
          type = lib.types.port;
          default = 4316;
          description = "Loopback Alloy OTLP HTTP port fronted by Traefik.";
        };
        authUser = lib.mkOption {
          type = lib.types.str;
          default = "activitylog";
          description = "Basic-auth username; the Android app sends this in its Instance ID field.";
        };
        authHash = lib.mkOption {
          type = lib.types.str;
          description = "bcrypt hash of the OTLP token (mkpasswd -m bcrypt). One-way, safe to commit.";
        };
      };

      config = lib.mkIf cfg.enable {
        my.services.alloy = {
          enable = true;
          stabilityLevel = "experimental";
          configs.activitylog = alloyConfig;
        };

        services.traefik.dynamicConfigOptions.http = {
          middlewares.activitylog.basicAuth = {
            users = [ "${cfg.authUser}:${cfg.authHash}" ];
            realm = "activitylog";
          };
          routers.activitylog = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`${cfg.otlpHostname}`)";
            service = "activitylog";
            tls.certResolver = "letsencrypt";
            middlewares = [ "activitylog" ];
          };
          services.activitylog.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString cfg.otlpPort}"; }
          ];
        };

        services.grafana.provision.dashboards.settings.providers = [
          {
            name = "activitylog";
            options.path = ./activitylog-dashboards;
            allowUiUpdates = false;
            disableDeletion = false;
          }
        ];
      };
    };
}
