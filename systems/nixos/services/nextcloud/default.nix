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

    config = {
      dbtype = "pgsql";
      adminuser = "root";
      adminpassFile = config.sops.secrets."nextcloud-admin-pass".path;
    };
  };
}
