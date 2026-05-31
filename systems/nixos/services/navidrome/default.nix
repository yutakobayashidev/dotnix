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

  services.traefik.dynamicConfigOptions.http = {
    routers.navidrome = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`music.home.yutakobayashi.com`)";
      service = "navidrome";
      tls.certResolver = "letsencrypt";
    };
    services.navidrome.loadBalancer.servers = [ { url = "http://localhost:4533"; } ];
  };
}
