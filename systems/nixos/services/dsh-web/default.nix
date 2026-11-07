_:

{
  # dsh runs as the personal user on UM790-Pro; TLS terminates here on B450M-Pro4.
  services.traefik.dynamicConfigOptions.http = {
    routers.dsh-web = {
      entryPoints = [ "websecure" ];
      rule = "Host(`dsh.home.yutakobayashi.com`)";
      service = "dsh-web";
      middlewares = [ "dsh-web-tailnet" ];
      tls.certResolver = "letsencrypt";
    };
    services.dsh-web.loadBalancer.servers = [
      { url = "http://um790-pro.tail29d068.ts.net:3081"; }
    ];
    middlewares.dsh-web-tailnet.ipAllowList.sourceRange = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
  };
}
