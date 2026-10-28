{ config, ... }:

let
  tokenFile = "/run/home-assistant-metrics/token";
in
{
  services = {
    home-assistant.config.prometheus = {
      namespace = "homeassistant";
      requires_auth = true;
      filter.include_domains = [
        "sensor"
        "binary_sensor"
        "climate"
        "light"
        "switch"
        "lock"
      ];
    };

    victoriametrics = {
      enable = true;
      # The bearer token exists only at runtime, outside the Nix store.
      checkConfig = false;
      prometheusConfig.scrape_configs = [
        {
          job_name = "home-assistant";
          scrape_interval = "60s";
          metrics_path = "/api/prometheus";
          bearer_token_file = tokenFile;
          static_configs = [
            {
              targets = [ "127.0.0.1:8123" ];
              labels.host = config.networking.hostName;
            }
          ];
        }
      ];
    };

    grafana.provision.datasources.settings.datasources = [
      {
        name = "Home Assistant";
        uid = "home-assistant";
        type = "prometheus";
        url = "http://127.0.0.1:8428";
      }
    ];
  };

  my.services.roomAlerts.enable = true;

  # Reuse the full Bearer authorization value already managed by sops for MCP.
  # Only its token portion belongs in VictoriaMetrics' bearer_token_file.
  users.groups.home-assistant-metrics = { };
  sops.secrets.home-assistant-mcp-authorization.restartUnits = [
    "home-assistant-metrics-token.service"
    "victoriametrics.service"
  ];
  systemd.services.home-assistant-metrics-token = {
    description = "Prepare Home Assistant metrics token from sops authorization";
    before = [ "victoriametrics.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "home-assistant-metrics";
      RuntimeDirectory = "home-assistant-metrics";
      RuntimeDirectoryMode = "0750";
      UMask = "0027";
      LoadCredential = [
        "ha-authorization:${config.sops.secrets.home-assistant-mcp-authorization.path}"
      ];
    };
    script = ''
      IFS= read -r authorization < "$CREDENTIALS_DIRECTORY/ha-authorization" || [ -n "$authorization" ]
      case "$authorization" in
        "Bearer "?*) token="''${authorization#Bearer }" ;;
        *) echo "Home Assistant authorization must contain Bearer followed by a token" >&2; exit 1 ;;
      esac
      case "$token" in
        *[[:space:]]*) echo "Home Assistant token must not contain whitespace" >&2; exit 1 ;;
      esac
      printf '%s' "$token" > ${tokenFile}
    '';
  };
  systemd.services.victoriametrics = {
    # A token preparation failure leaves HA scraping unavailable but does not
    # prevent the shared database from collecting infrastructure metrics.
    wants = [ "home-assistant-metrics-token.service" ];
    after = [ "home-assistant-metrics-token.service" ];
    serviceConfig.SupplementaryGroups = [ "home-assistant-metrics" ];
  };
}
