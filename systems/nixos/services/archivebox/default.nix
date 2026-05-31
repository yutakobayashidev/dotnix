{
  ...
}:

let
  archiveboxPort = 8000;
in
{
  virtualisation.oci-containers.containers.archivebox = {
    image = "ghcr.io/archivebox/archivebox:main";
    ports = [ "127.0.0.1:${toString archiveboxPort}:8000" ];
    volumes = [
      "/srv/bulk/archivebox/data:/data"
    ];
    environment = {
      ALLOWLIST_HOSTS = "localhost,127.0.0.1,archive.home.yutakobayashi.com";
      CSRF_TRUSTED_ORIGINS = "http://127.0.0.1:${toString archiveboxPort},http://archive.home.yutakobayashi.com";
      REVERSE_PROXY_USER_HEADER = "X-Remote-User";
      REVERSE_PROXY_WHITELIST = "127.0.0.1/32,100.86.129.23/32";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/bulk/archivebox 0755 root root -"
    "d /srv/bulk/archivebox/data 0755 root root -"
  ];

  systemd.services.docker-archivebox.unitConfig.RequiresMountsFor = [ "/srv/bulk/archivebox/data" ];

  services.traefik.dynamicConfigOptions.http = {
    routers.archivebox = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`archive.home.yutakobayashi.com`)";
      service = "archivebox";
      tls.certResolver = "letsencrypt";
    };
    services.archivebox.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString archiveboxPort}"; }
    ];
  };
}
