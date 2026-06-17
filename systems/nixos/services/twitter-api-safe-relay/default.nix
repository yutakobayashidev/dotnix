{ ... }:
let
  port = 3090;
  domain = "tw.home.yutakobayashi.com";
in
{
  virtualisation.oci-containers.containers.twitter-api-safe-relay = {
    image = "ghcr.io/fa0311/twitter_api_safe_relay:sha-c6af1d2-dashboard";
    ports = [ "127.0.0.1:${toString port}:3000" ];
    volumes = [
      "${./settings.json}:/app/settings.json:ro"
    ];
    extraOptions = [
      "--restart=unless-stopped"
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.twitter-api-safe-relay = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "twitter-api-safe-relay";
      tls.certResolver = "letsencrypt";
    };
    services.twitter-api-safe-relay.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString port}"; }
    ];
  };
}
