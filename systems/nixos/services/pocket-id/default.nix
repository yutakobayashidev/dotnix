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
      # UI-managed settings are otherwise read from the database, ignoring env.
      UI_CONFIG_DISABLED = true;
      ALLOW_USER_SIGNUPS = "disabled";
      CIMD_URL_ALLOWLIST = builtins.toJSON [
        "https://claude.ai/oauth/mcp-oauth-client-metadata"
        "https://claude.ai/oauth/claude-code-client-metadata"
        "https://chatgpt.com/oauth/codex/client.json"
      ];
    };
    credentials.ENCRYPTION_KEY = config.sops.secrets.pocket-id-encryption-key.path;
    credentials.STATIC_API_KEY = config.sops.secrets.pocket-id-api-key.path;
  };

  # A previous instance's database lease can outlive an abrupt reboot.
  # Keep retrying slowly instead of exhausting the start limit in seconds.
  systemd.services.pocket-id.serviceConfig.RestartSec = lib.mkForce "30s";

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
