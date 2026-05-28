{ pkgs, ... }:
let
  repoDir = "/home/yuta/ghq/github.com/fa0311/twitter_api_safe_proxy";
  outputDir = "/var/lib/immich-net-pics";
in
{
  systemd.services.twitter-bookmark-snap = {
    description = "Fetch and render Twitter bookmarks";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [
      bash
      pnpm
      nodejs
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "yuta";
      WorkingDirectory = repoDir;
      Environment = "DISPLAY=:99";
    };
    script = ''
      pnpm --filter twitter-bookmark-snap start -- --limit 50 --output-dir ${outputDir}
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
