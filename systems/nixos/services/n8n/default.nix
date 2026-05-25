{ ... }:

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
}
