{ ... }:

let
  domain = "git.yutakobayashi.com";
in
{
  services.gitea = {
    enable = true;
    settings = {
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
      };
      service.DISABLE_REGISTRATION = true;
    };
  };

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "http://localhost:3000";
  };
}
