{ config, ... }:

{
  sops.secrets.omniroute-env = {
    sopsFile = ./secrets.env;
    format = "dotenv";
    key = "";
  };
  # Keep the existing source shared with dsh and available for key rotation.
  sops.secrets."litellm/opencode-go-key".sopsFile = ../litellm/secrets.yaml;

  services.omniroute = {
    enable = true;
    environmentFiles = [ config.sops.secrets.omniroute-env.path ];
    settings = {
      PORT = 20128;
      OMNIROUTE_SERVER_HOST = "127.0.0.1";
      REQUIRE_API_KEY = true;
      # Preserve the existing LiteLLM client/master key during migration.
      OMNIROUTE_API_KEY = "sk-proxy";
      OMNIROUTE_SHOW_LOG = true;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    # Preserve the endpoint used by Birdclaw, skillspector, and other clients.
    routers.litellm = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`litellm.home.yutakobayashi.com`)";
      service = "omniroute";
      tls.certResolver = "letsencrypt";
    };
    services.omniroute.loadBalancer.servers = [
      { url = "http://127.0.0.1:20128"; }
    ];
  };
}
