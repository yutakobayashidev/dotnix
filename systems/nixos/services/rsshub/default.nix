{ pkgs, ... }:
let
  domain = "rsshub.home.yutakobayashi.com";
  port = 1200;
in
{
  services.rsshub = {
    enable = true;
    settings = {
      PORT = port;
      USER_ROUTES_PATH = "${./routes}";
      DISTANCE_MEDIA_DATA_PATH = "/var/lib/rsshub/distanceposts.json";
    };
    redis.enable = true;
  };

  # Feed requests only read this snapshot; upstream requests run on a fixed schedule.
  systemd.services.rsshub-distance-media = {
    description = "Refresh the DISTANCE MEDIA article snapshot for RSSHub";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [
      pkgs.curl
      pkgs.jq
      pkgs.coreutils
    ];
    script = ''
      umask 022
      snapshot=/var/lib/rsshub/distanceposts.json
      trap 'rm -f "$snapshot.tmp"' EXIT
      curl --fail --silent --show-error --max-time 30 \
        https://distance.media/dist/js/distanceposts.json > "$snapshot.tmp"
      jq -e '.data | type == "array"' "$snapshot.tmp" > /dev/null
      mv "$snapshot.tmp" "$snapshot"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "rsshub";
      Group = "rsshub";
      DynamicUser = true;
      StateDirectory = "rsshub";
      TimeoutStartSec = "45s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };

  systemd.timers.rsshub-distance-media = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30min";
    };
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
