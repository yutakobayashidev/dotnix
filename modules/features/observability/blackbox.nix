_: {
  flake.modules.nixos.blackbox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      exporter = config.services.prometheus.exporters.blackbox;
      exporterAddress = "${exporter.listenAddress}:${toString exporter.port}";
      targets = {
        grafana = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}/api/health";
        loki = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/ready";
        victoriametrics = "http://${config.services.victoriametrics.listenAddress}/-/healthy";
        gitea = "http://127.0.0.1:${toString config.services.gitea.settings.server.HTTP_PORT}/api/healthz";
        starla = "http://${config.services.starla.metrics.listenAddr}/health";
        # HA manages its HTTP port in the UI; use the same backend as Traefik.
        home-assistant =
          (builtins.head config.services.traefik.dynamicConfigOptions.http.services.home-assistant.loadBalancer.servers)
          .url
          + "/";
      };
    in
    {
      config = lib.mkIf config.my.services.monitoring.enable {
        services.prometheus.exporters.blackbox = {
          enable = true;
          listenAddress = "127.0.0.1";
          configFile = (pkgs.formats.yaml { }).generate "blackbox.yml" {
            modules.http_200 = {
              prober = "http";
              timeout = "5s";
              http = {
                valid_status_codes = [ 200 ];
                follow_redirects = false;
                preferred_ip_protocol = "ip4";
              };
            };
          };
        };

        services.victoriametrics.prometheusConfig.scrape_configs = [
          {
            job_name = "blackbox";
            metrics_path = "/probe";
            params.module = [ "http_200" ];
            static_configs = lib.mapAttrsToList (service: url: {
              targets = [ url ];
              labels = {
                inherit service;
                host = config.networking.hostName;
                instance = service;
              };
            }) targets;
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                target_label = "__address__";
                replacement = exporterAddress;
              }
            ];
          }
          {
            job_name = "blackbox-exporter";
            static_configs = [
              {
                targets = [ exporterAddress ];
                labels.host = config.networking.hostName;
              }
            ];
          }
        ];

        services.vmalert.instances.main.rules.groups = [
          {
            name = "blackbox";
            rules = [
              {
                alert = "ServiceProbeFailed";
                expr = ''probe_success{job="blackbox"} == 0'';
                for = "5m";
                labels = {
                  severity = "warning";
                  category = "infra";
                };
                annotations.summary = "{{ $labels.host }}: {{ $labels.service }} health check failed";
              }
              {
                alert = "ServiceProbeScrapeFailed";
                expr = ''up{job="blackbox"} == 0'';
                for = "5m";
                labels = {
                  severity = "warning";
                  category = "infra";
                };
                annotations.summary = "Cannot collect the {{ $labels.service }} probe on {{ $labels.host }}";
              }
              {
                alert = "BlackboxExporterDown";
                expr = ''up{job="blackbox-exporter"} == 0'';
                for = "5m";
                labels = {
                  severity = "critical";
                  category = "infra";
                };
                annotations.summary = "HTTP monitoring exporter is unreachable on {{ $labels.host }}";
              }
            ];
          }
        ];
      };
    };
}
