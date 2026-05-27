{ config, ... }:
{
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/srv/bulk/music";
      EnableSharing = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/bulk/music 2775 yuta users - -"
    "d /srv/bulk/music/_inbox 2775 yuta users - -"
  ];
}
