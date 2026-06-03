{
  ...
}:
let
  domain = "rsshub.home.yutakobayashi.com";
  port = 1200;
in
{
  services.rsshub = {
    enable = true;
    settings = {
      PORT = port;
    };
    redis.enable = true;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.rsshub = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "rsshub";
      tls.certResolver = "letsencrypt";
    };
    services.rsshub.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString port}"; }
    ];
  };
}
