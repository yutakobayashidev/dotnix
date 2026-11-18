{ inputs, ... }:
let
  domain = "noren.home.yutakobayashi.com";
  port = 3101;
in
{
  imports = [ inputs.noren.nixosModules.default ];

  services.noren = {
    enable = true;
    inherit port;
    settings = {
      APP_ORIGIN = "https://${domain}";
      OIDC_ISSUER = "https://id.yutakobayashi.com";
      OIDC_CLIENT_ID = "noren";
      # The relay profiles belong to this Pocket ID user.
      OIDC_ALLOWED_SUBJECTS = "a3a3549f-6584-4c36-aa27-4492fc35420e";
      TWITTER_RELAY_BASE_URL = "http://127.0.0.1:18788";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.noren = {
      entryPoints = [ "websecure" ];
      rule = "Host(`${domain}`)";
      service = "noren";
      tls.certResolver = "letsencrypt";
    };
    services.noren.loadBalancer.servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
  };
}
