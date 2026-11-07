_:

{
  services.traefik.dynamicConfigOptions.http = {
    routers.opencode-web = {
      entryPoints = [ "websecure" ];
      rule = "Host(`opencode.home.yutakobayashi.com`)";
      service = "opencode-web";
      middlewares = [ "opencode-web-tailnet" ];
      tls.certResolver = "letsencrypt";
    };
    services.opencode-web.loadBalancer.servers = [
      { url = "http://um790-pro.tail29d068.ts.net:4096"; }
    ];
    middlewares.opencode-web-tailnet.ipAllowList.sourceRange = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
  };
}
