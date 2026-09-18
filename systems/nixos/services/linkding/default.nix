_:
let
  domain = "linkding.home.yutakobayashi.com";
  port = 9091;
in
{
  services.linkding = {
    enable = true;
    inherit port;
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
