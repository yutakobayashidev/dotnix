{ ... }:

let
  domain = "home.yutakobayashi.com";
in
{
  services.gitea = {
    enable = true;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.gitea = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`git.${domain}`)";
      service = "gitea";
      tls = {
        certResolver = "letsencrypt";
        domains = [
          {
            main = domain;
            sans = [ "*.${domain}" ];
          }
        ];
      };
    };
    services.gitea.loadBalancer.servers = [ { url = "http://localhost:3000"; } ];
  };
}
