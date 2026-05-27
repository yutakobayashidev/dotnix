{ config, pkgs, ... }:
{
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/srv/bulk/music";
      EnableSharing = true;
      EnableTranscodingConfig = true;
      TranscodingCacheSize = "100MiB";
    };
  };

  systemd.services.navidrome.path = [ pkgs.ffmpeg ];

  systemd.tmpfiles.rules = [
    "d /srv/bulk/music 2775 yuta users - -"
    "d /srv/bulk/music/_inbox 2775 yuta users - -"
  ];
}
