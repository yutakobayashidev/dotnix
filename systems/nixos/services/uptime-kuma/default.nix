{
  ...
}:

{
  services.uptime-kuma = {
    enable = true;
    settings.PORT = "3002";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.uptime-kuma = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`status.home.yutakobayashi.com`)";
      service = "uptime-kuma";
      tls.certResolver = "letsencrypt";
    };
    services.uptime-kuma.loadBalancer.servers = [ { url = "http://localhost:3002"; } ];
  };
}
