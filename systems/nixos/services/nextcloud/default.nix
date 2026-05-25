{ config, pkgs, ... }:
{
  sops.secrets."nextcloud-admin-pass" = {
    sopsFile = ./secrets/default.yaml;
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "localhost";
    configureRedis = true;
    datadir = "/srv/bulk/nextcloud";

    database.createLocally = true;

    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
      adminuser = "root";
      adminpassFile = config.sops.secrets."nextcloud-admin-pass".path;
    };

    settings.trusted_domains = [
      "localhost"
      "cloud.home.yutakobayashi.com"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/bulk/nextcloud 0750 nextcloud nextcloud -"
    "d /srv/bulk/nextcloud/data 0750 nextcloud nextcloud -"
    "z /srv/bulk/nextcloud 0750 nextcloud nextcloud -"
    "z /srv/bulk/nextcloud/data 0750 nextcloud nextcloud -"
  ];

  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [
    config.services.nextcloud.datadir
  ];
  systemd.services.phpfpm-nextcloud.unitConfig.RequiresMountsFor = [
    config.services.nextcloud.datadir
  ];
  systemd.services.nextcloud-cron.unitConfig.RequiresMountsFor = [
    config.services.nextcloud.datadir
  ];
}
