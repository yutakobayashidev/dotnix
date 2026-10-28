{
  config,
  pkgs,
  ...
}:
let
  serviceName = "tunnel-client-grafana";
  credentialDir = "/run/credentials/${serviceName}.service";
  environmentFile = "/var/lib/grafana-mcp/mcp-tunnel.env";
  grafanaMcp = pkgs.mcp-grafana;
in
{
  sops.secrets.grafana-mcp-token = {
    sopsFile = ../../../../secrets/grafana-mcp.yaml;
    restartUnits = [ "${serviceName}.service" ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/grafana-mcp 0700 root root -" ];

  services.openai-tunnel-client.instances.grafana = {
    enable = true;
    environment = {
      GRAFANA_URL = "https://grafana.home.yutakobayashi.com";
      GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE = "${credentialDir}/grafana-token";
    };
    settings = {
      config_version = 1;
      control_plane.api_key = "file:${credentialDir}/control-plane-api-key";
      health.listen_addr = "127.0.0.1:18794";
      admin_ui.open_browser = false;
      mcp.commands = [
        {
          channel = "main";
          command = "${grafanaMcp}/bin/mcp-grafana --disable-write";
        }
      ];
    };
  };

  systemd.services.${serviceName} = {
    after = [ "grafana.service" ];
    wants = [ "grafana.service" ];
    unitConfig.ConditionPathExists = environmentFile;
    serviceConfig = {
      EnvironmentFile = environmentFile;
      LoadCredential = [
        "control-plane-api-key:${config.sops.secrets.openai-tunnel-api-key.path}"
        "grafana-token:${config.sops.secrets.grafana-mcp-token.path}"
      ];
    };
  };
}
