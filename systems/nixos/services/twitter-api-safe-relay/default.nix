{ pkgs, lib, ... }:
let
  port = 3090;
  domain = "tw.home.yutakobayashi.com";
  outputDir = "/var/lib/immich-net-pics";

  bookmark-snap = pkgs.buildNpmPackage {
    pname = "twitter-bookmark-snap";
    version = "0.0.1";
    src = ./bookmark-snap;
    npmDepsHash = "sha256-6SWm/yoihgX6STzNd+4sazIibpn8qYlO9ll4bFohkUg=";
    PUPPETEER_SKIP_DOWNLOAD = true;
    dontNpmBuild = true;

    buildPhase = ''
      ${lib.getExe pkgs.nodejs} node_modules/typescript/bin/tsc
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp -r dist $out/lib/
      cp -r node_modules $out/lib/
    '';
  };
in
{
  virtualisation.oci-containers.containers.twitter-api-safe-relay = {
    image = "ghcr.io/fa0311/twitter_api_safe_relay:sha-c6af1d2-dashboard";
    ports = [ "127.0.0.1:${toString port}:3000" ];
    volumes = [
      "${./settings.json}:/app/settings.json:ro"
    ];
    extraOptions = [ ];
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

  systemd.tmpfiles.rules = [
    "d ${outputDir} 0755 yuta users - -"
  ];

  systemd.services.twitter-bookmark-snap = {
    description = "Fetch and render Twitter bookmarks";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "yuta";
      WorkingDirectory = "${bookmark-snap}/lib";
    };
    script = ''
      ${lib.getExe pkgs.nodejs} dist/index.js -- --limit 50 --output-dir ${outputDir}
    '';
  };

  systemd.timers.twitter-bookmark-snap = {
    description = "Run twitter-bookmark-snap every 15 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      RandomizedDelaySec = "2min";
      Persistent = true;
    };
  };
}
