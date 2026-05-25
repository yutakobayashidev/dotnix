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

    settings.trusted_domains = [
      "localhost"
      "cloud.home.yutakobayashi.com"
    ];
  };
}
