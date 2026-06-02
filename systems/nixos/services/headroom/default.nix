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
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
      ExecStart = lib.concatStringsSep " " [
        headroom
        "proxy"
        "--port"
        "8787"
        "--mode"
        "token"
        "--no-telemetry"
      ];
      User = "yuta";
    };

    environment = {
      HEADROOM_TELEMETRY = "off";
      HEADROOM_HOST = "127.0.0.1";
      HEADROOM_PORT = "8787";
      HEADROOM_MODE = "token";
      ORT_LOG_LEVEL = "3";
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
