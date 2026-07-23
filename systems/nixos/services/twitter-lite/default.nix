{ inputs, ... }:

let
  domain = "tw-lite.home.yutakobayashi.com";
  port = 3006;
in
{
  imports = [ inputs.twitter-lite.nixosModules.default ];

  services.twitter-lite = {
    enable = true;
    relayBaseUrl = "http://127.0.0.1:18788";
    profileName = "account1";
    inherit port;
  };

  systemd.services.twitter-lite = {
    after = [ "podman-twitter-api-safe-relay.service" ];
    wants = [ "podman-twitter-api-safe-relay.service" ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.twitter-lite = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "twitter-lite";
      tls.certResolver = "letsencrypt";
    };
    services.twitter-lite.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString port}"; }
    ];
  };
}
