{ config, lib, ... }:

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
    credentials.STATIC_API_KEY = config.sops.secrets.pocket-id-api-key.path;
  };

  sops.secrets = {
    pocket-id-encryption-key = {
      sopsFile = ../../../../secrets/pocket-id.yaml;
      key = "encryption-key";
      restartUnits = [ "pocket-id.service" ];
    };
    pocket-id-api-key = {
      sopsFile = ../../../../secrets/pocket-id-oidc.yaml;
      key = "static-api-key";
      restartUnits = [ "pocket-id.service" ];
    };
  }
  //
    lib.genAttrs
      (map (name: "oidc-${name}-client-secret") [
        "grafana"
        "linkding"
        "immich"
        "moe"
        "gitea"
        "nextcloud"
      ])
      (name: {
        sopsFile = ../../../../secrets/pocket-id-oidc.yaml;
        key = "client-secrets/${lib.removeSuffix "-client-secret" (lib.removePrefix "oidc-" name)}";
      });

  my.services.cloudflared-tunnel.ingress."id.yutakobayashi.com" = {
    service = "http://127.0.0.1:1411";
  };
}
