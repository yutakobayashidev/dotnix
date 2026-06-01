{ ... }:

let
  archiveboxPort = 8000;
in
{
  services.archivebox = {
    enable = true;
    webserver = {
      enable = true;
      port = archiveboxPort;
    };
    jobs = {
      radar = {
        opmlUrl = "https://radar.yutakobayashi.com/sources.opml";
        startAt = "daily";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/bulk/archivebox 0755 root root -"
    "d /srv/bulk/archivebox/data 0755 archivebox archivebox -"
  ];

  fileSystems."/var/lib/archivebox" = {
    device = "/srv/bulk/archivebox/data";
    fsType = "none";
    options = [ "bind" ];
  };

  systemd.services.archivebox-server.unitConfig.RequiresMountsFor = [ "/var/lib/archivebox" ];

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
