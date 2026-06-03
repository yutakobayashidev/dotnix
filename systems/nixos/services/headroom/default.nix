{
  lib,
  pkgs,
  ...
}:
let
  headroom = "${pkgs.headroom-ai}/bin/headroom-proxy";
in
{
  systemd.services.headroom-ai = {
    description = "headroom token compression proxy";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
      ExecStart = lib.concatStringsSep " " [
        headroom
        "--listen"
        "127.0.0.1:8787"
        "--upstream"
        "https://api.anthropic.com"
        "--compression"
      ];
      User = "yuta";
    };

    environment = {
      HEADROOM_PROXY_COMPRESSION = "1";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.headroom = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`headroom.home.yutakobayashi.com`)";
      service = "headroom";
      tls.certResolver = "letsencrypt";
    };
    services.headroom.loadBalancer.servers = [
      { url = "http://127.0.0.1:8787"; }
    ];
  };
}
