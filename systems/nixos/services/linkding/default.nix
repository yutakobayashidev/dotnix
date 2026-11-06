{ config, ... }:
let
  domain = "linkding.home.yutakobayashi.com";
  port = 9091;
in
{
  services.linkding = {
    enable = true;
    inherit port;
    settings = {
      LD_ENABLE_OIDC = "True";
      LD_DISABLE_LOGIN_FORM = "False";
      OIDC_RP_CLIENT_ID = "linkding";
      OIDC_RP_SCOPES = "openid profile email";
      OIDC_RP_SIGN_ALGO = "RS256";
      OIDC_USE_PKCE = "True";
      OIDC_OP_AUTHORIZATION_ENDPOINT = "https://id.yutakobayashi.com/authorize";
      OIDC_OP_TOKEN_ENDPOINT = "https://id.yutakobayashi.com/api/oidc/token";
      OIDC_OP_USER_ENDPOINT = "https://id.yutakobayashi.com/api/oidc/userinfo";
      OIDC_OP_JWKS_ENDPOINT = "https://id.yutakobayashi.com/.well-known/jwks.json";
      OIDC_USERNAME_CLAIM = "preferred_username";
    };
    environmentFile = config.sops.templates."linkding-oidc.env".path;
  };

  sops.templates."linkding-oidc.env" = {
    content = ''
      OIDC_RP_CLIENT_SECRET=${config.sops.placeholder.oidc-linkding-client-secret}
    '';
    restartUnits = [
      "linkding.service"
      "linkding-background-tasks.service"
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.linkding = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "linkding";
      tls.certResolver = "letsencrypt";
    };
    services.linkding.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString port}"; }
    ];
  };
}
