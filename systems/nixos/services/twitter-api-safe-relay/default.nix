{ pkgs, lib, ... }:
let
  domain = "tw.home.yutakobayashi.com";
  outputDir = "/var/lib/immich-net-pics";
  profileDir = "/var/lib/twitter-api-safe-relay/chrome-profile";

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
  virtualisation.oci-containers.containers = {
    kasmweb = {
      image = "kasmweb/chrome:1.18.0";
      ports = [ "6901:6901" ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.twitter-api-safe-relay.rule" = "Host(`${domain}`)";
        "traefik.http.routers.twitter-api-safe-relay.entrypoints" = "web,websecure";
        "traefik.http.routers.twitter-api-safe-relay.tls.certResolver" = "letsencrypt";
        "traefik.http.services.twitter-api-safe-relay.loadbalancer.server.port" = "3000";
      };
      volumes = [
        "${profileDir}:/home/kasm-user/chrome-profile"
      ];
      environment = {
        VNC_PW = "password";
        APP_ARGS = "--start-maximized --user-data-dir=/home/kasm-user/chrome-profile --password-store=basic --remote-debugging-port=9222";
      };
      extraOptions = [
        "--shm-size=4g"
      ];
    };

    twitter-api-safe-relay = {
      image = "ghcr.io/fa0311/twitter_api_safe_relay:sha-c6af1d2-dashboard";
      volumes = [
        "${./settings.json}:/app/settings.json:ro"
      ];
      dependsOn = [ "kasmweb" ];
      extraOptions = [
        "--network=container:kasmweb"
      ];
    };
  };

  systemd.services.podman-kasmweb.preStart = ''
    rm -f ${profileDir}/SingletonLock ${profileDir}/SingletonSocket ${profileDir}/SingletonCookie ${profileDir}/DevToolsActivePort
    chown -R 1000:0 ${profileDir}
    chmod -R g+rwX ${profileDir}
  '';

  systemd.tmpfiles.rules = [
    "d ${outputDir} 0755 yuta users - -"
    "d ${profileDir} 0755 1000 0 - -"
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
