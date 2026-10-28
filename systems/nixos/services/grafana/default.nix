{ config, ... }:

{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3001;
        enable_gzip = true;
      };
      security.secret_key = "$__file{${config.sops.secrets.grafana-secret-key.path}}";
      analytics.reporting_enabled = false;
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "PBFA97CFB590B2093";
          url = "http://127.0.0.1:8428";
          isDefault = true;
          jsonData.timeInterval = "1m";
        }
        {
          name = "Loki";
          type = "loki";
          uid = "loki";
          jsonData.derivedFields = [
            {
              name = "trace_id";
              matcherType = "label";
              matcherRegex = "trace_id";
              datasourceUid = "tempo";
              url = "\${__value.raw}";
              urlDisplayLabel = "View trace";
            }
          ];
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "nix-managed";
            options.path = "${./dashboards}";
            options.foldersFromFilesStructure = true;
            allowUiUpdates = false;
            disableDeletion = true;
          }
        ];
      };
    };
  };

  sops.secrets.grafana-secret-key = {
    sopsFile = ./secrets.yaml;
    owner = "grafana";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.grafana = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`grafana.home.yutakobayashi.com`)";
      service = "grafana";
      tls.certResolver = "letsencrypt";
    };
    services.grafana.loadBalancer.servers = [
      { url = "http://localhost:${toString config.services.grafana.settings.server.http_port}"; }
    ];
  };
}
