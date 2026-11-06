{ config, ... }:

{
  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://id.yutakobayashi.com";
      HOST = "127.0.0.1";
      PORT = 1411;
      TRUST_PROXY = true;
      TRUSTED_PLATFORM = "CF-Connecting-IP";
      ANALYTICS_DISABLED = true;
    };
    credentials.ENCRYPTION_KEY = config.sops.secrets.pocket-id-encryption-key.path;
  };

  sops.secrets.pocket-id-encryption-key = {
    sopsFile = ../../../../secrets/pocket-id.yaml;
    key = "encryption-key";
    restartUnits = [ "pocket-id.service" ];
  };

  my.services.cloudflared-tunnel.ingress."id.yutakobayashi.com" = {
    service = "http://127.0.0.1:1411";
  };
}
