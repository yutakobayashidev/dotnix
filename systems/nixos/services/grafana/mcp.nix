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
  mcpAddress = "127.0.0.1:18994";
in
{
  sops.secrets.grafana-mcp-token = {
    sopsFile = ../../../../secrets/grafana-mcp.yaml;
    restartUnits = [ "grafana-mcp.service" ];
  };

  services.openai-tunnel-client.instances.grafana = {
    enable = true;
    settings = {
      config_version = 1;
      control_plane.api_key = "file:${credentialDir}/control-plane-api-key";
      health.listen_addr = "127.0.0.1:18794";
      admin_ui.open_browser = false;
      mcp.server_urls = [
        {
          channel = "main";
          url = "http://${mcpAddress}/mcp";
        }
      ];
    };
  };

  systemd = {
    tmpfiles.rules = [ "d /var/lib/grafana-mcp 0700 root root -" ];
    services.grafana-mcp = {
      description = "Grafana MCP over stateless Streamable HTTP";
      wantedBy = [ "multi-user.target" ];
      after = [ "grafana.service" ];
      wants = [ "grafana.service" ];
      environment = {
        GRAFANA_URL = "https://grafana.home.yutakobayashi.com";
        GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE = "/run/credentials/grafana-mcp.service/grafana-token";
      };
      serviceConfig = {
        ExecStart = "${grafanaMcp}/bin/mcp-grafana --disable-write --transport streamable-http --address ${mcpAddress}";
        DynamicUser = true;
        LoadCredential = [ "grafana-token:${config.sops.secrets.grafana-mcp-token.path}" ];
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Tailnet-only forwarder so MCP clients on the tailnet (e.g. Muse) can
    # reach mcp-grafana directly. The OpenAI tunnel above only serves
    # ChatGPT, so it cannot be reused by other MCP clients. mcp-grafana
    # itself stays bound to loopback; this forwarder listens solely on this
    # host's Tailscale address (100.111.109.43) and the firewall already
    # trusts tailscale0. mcp-grafana runs read-only (--disable-write), and
    # reaching this port requires tailnet access.
    services.grafana-mcp-tailnet = {
      description = "Grafana MCP forwarded on the tailnet for Muse";
      after = [
        "grafana-mcp.service"
        "tailscaled.service"
      ];
      wants = [ "grafana-mcp.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:18995,bind=100.111.109.43,fork,reuseaddr TCP:127.0.0.1:18994";
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    services.${serviceName} = {
      after = [ "grafana-mcp.service" ];
      wants = [ "grafana-mcp.service" ];
      unitConfig.ConditionPathExists = environmentFile;
      serviceConfig = {
        EnvironmentFile = environmentFile;
        LoadCredential = [
          "control-plane-api-key:${config.sops.secrets.openai-tunnel-api-key.path}"
        ];
      };
    };
  };
}
