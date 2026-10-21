_:

let
  tokenFile = "/var/lib/home-assistant-secrets/prometheus-token";
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
      ];
    };

    victoriametrics = {
      enable = true;
      listenAddress = "127.0.0.1:8428";
      retentionPeriod = "1y";
      # The bearer token exists only at runtime, outside the Nix store.
      checkConfig = false;
      prometheusConfig.scrape_configs = [
        {
          job_name = "home-assistant";
          scrape_interval = "60s";
          metrics_path = "/api/prometheus";
          bearer_token_file = "/run/credentials/victoriametrics.service/ha-token";
          static_configs = [ { targets = [ "127.0.0.1:8123" ]; } ];
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

  systemd.tmpfiles.rules = [ "d /var/lib/home-assistant-secrets 0700 root root -" ];
  systemd.services.victoriametrics = {
    unitConfig.ConditionPathExists = tokenFile;
    serviceConfig.LoadCredential = [ "ha-token:${tokenFile}" ];
  };

}
