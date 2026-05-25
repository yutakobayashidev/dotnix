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

    database.createLocally = true;

    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
      adminuser = "root";
      adminpassFile = config.sops.secrets."nextcloud-admin-pass".path;
    };

    settings = {
      trusted_domains = [
        "localhost"
        "cloud.home.yutakobayashi.com"
      ];
      trusted_proxies = [ "127.0.0.1" ];
      "ratelimit.protection.enabled" = false;
    };
  };

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
