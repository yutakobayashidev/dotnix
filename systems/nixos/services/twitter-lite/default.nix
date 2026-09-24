_:

let
  domain = "tw-lite.home.yutakobayashi.com";
  port = 3006;
in
{
  # The app and Codex run as yuta's user services on UM790-Pro.
  services.traefik.dynamicConfigOptions.http = {
    routers.twitter-lite = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "twitter-lite";
      middlewares = [ "twitter-lite-tailnet" ];
      tls.certResolver = "letsencrypt";
    };
    services.twitter-lite.loadBalancer.servers = [
      { url = "http://um790-pro.tail29d068.ts.net:${toString port}"; }
    ];
    # Use the TCP peer address, not client-supplied forwarded headers.
    middlewares.twitter-lite-tailnet.ipAllowList.sourceRange = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
  };
}
