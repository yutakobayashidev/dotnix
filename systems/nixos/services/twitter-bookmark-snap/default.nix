{
  lib,
  pkgs,
  ...
}:

let
  outputDir = "/var/lib/immich-net-pics";
  package = pkgs.buildNpmPackage {
    pname = "twitter-bookmark-snap";
    version = "0.0.1";
    src = ./app;
    npmDepsHash = "sha256-H2WmmgdWRdVx6fOrTjDtXB8btkAxSsj/pTIu0N66JfQ=";
    PUPPETEER_SKIP_DOWNLOAD = true;
    dontNpmBuild = true;

    postConfigure = ''
      patch -p1 < ${./twitter-snap-safe-relay.patch}
    '';

    buildPhase = ''
      ${lib.getExe pkgs.nodejs} node_modules/typescript/bin/tsc
    '';

    doCheck = true;
    checkPhase = ''
      FFMPEG_PATH=${pkgs.ffmpeg}/bin/ffmpeg ${lib.getExe pkgs.nodejs} test/storage.mjs
      ${lib.getExe pkgs.nodejs} test/relay.mjs
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp -r dist $out/lib/
      cp -r node_modules $out/lib/
    '';
  };
in
{
  systemd = {
    services.twitter-bookmark-snap = {
      description = "Fetch and render Twitter bookmarks";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = [ outputDir ];
      environment = {
        TWITTER_SNAP_RELAY_URL = "https://tw.home.yutakobayashi.com";
        PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        FFMPEG_PATH = "${pkgs.ffmpeg}/bin/ffmpeg";
        FFPROBE_PATH = "${pkgs.ffmpeg}/bin/ffprobe";
      };
      serviceConfig = {
        Type = "oneshot";
        User = "yuta";
        WorkingDirectory = "${package}/lib";
      };
      script = ''
        ${lib.getExe pkgs.nodejs} dist/index.js -- --limit 50 --output-dir ${outputDir}
      '';
    };

    timers.twitter-bookmark-snap = {
      description = "Run twitter-bookmark-snap every 15 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        RandomizedDelaySec = "2min";
        Persistent = true;
      };
    };

    tmpfiles.rules = [
      "d ${outputDir} 0755 yuta users - -"
    ];
  };
}
