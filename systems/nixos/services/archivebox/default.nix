{ ... }:
{
  my.services.archivebox = {
    enable = true;
    jobs = {
      radar = {
        opmlUrl = "https://radar.yutakobayashi.com/sources.opml";
        parseFeeds = true;
        extraArgs = [
          "--parser=rss"
          "--depth"
          "0"
        ];
        startAt = "daily";
      };
    };
  };

  virtualisation.oci-containers.containers.archivebox = {
    image = "ghcr.io/archivebox/archivebox:main";
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.archivebox.rule" = "Host(`archive.home.yutakobayashi.com`)";
      "traefik.http.routers.archivebox.entrypoints" = "web,websecure";
      "traefik.http.routers.archivebox.tls.certResolver" = "letsencrypt";
      "traefik.http.services.archivebox.loadbalancer.server.port" = "8000";
    };
    volumes = [
      "/srv/bulk/archivebox/data:/data"
    ];
    environment = {
      ALLOWLIST_HOSTS = "localhost,127.0.0.1,archive.home.yutakobayashi.com";
      CSRF_TRUSTED_ORIGINS = "http://127.0.0.1:8000,http://archive.home.yutakobayashi.com";
      REVERSE_PROXY_USER_HEADER = "X-Remote-User";
      REVERSE_PROXY_WHITELIST = "127.0.0.1/32,100.86.129.23/32";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/bulk/archivebox 0755 root root -"
    "d /srv/bulk/archivebox/data 0755 root root -"
  ];

  systemd.services.podman-archivebox.unitConfig.RequiresMountsFor = [ "/srv/bulk/archivebox/data" ];
}
