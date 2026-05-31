{ config, ... }:

let
  host = "n8n.home.yutakobayashi.com";
in
{
  services.n8n = {
    enable = true;
    environment = {
      N8N_HOST = host;
      N8N_LISTEN_ADDRESS = "127.0.0.1";
      N8N_PROTOCOL = "http";
      WEBHOOK_URL = "http://${host}/";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.n8n = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`n8n.home.yutakobayashi.com`)";
      service = "n8n";
      tls.certResolver = "letsencrypt";
    };
    services.n8n.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString config.services.n8n.environment.N8N_PORT}"; }
    ];
  };
}
