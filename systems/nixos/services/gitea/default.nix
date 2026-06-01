{ ... }:

let
  domain = "git.yutakobayashi.com";
in
{
  services.gitea = {
    enable = true;
    settings.server = {
      DOMAIN = domain;
      ROOT_URL = "https://${domain}/";
    };
  };

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "http://localhost:3000";
  };
}
