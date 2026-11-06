{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "localhost";
    configureRedis = true;
    extraApps = {
      inherit (pkgs.nextcloud33Packages.apps) user_oidc;
    };
    extraAppsEnable = true;
    appstoreEnable = true;

    database.createLocally = true;

    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
    };

    settings = {
      trusted_domains = [
        "localhost"
        "cloud.home.yutakobayashi.com"
      ];
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
      overwritehost = "cloud.home.yutakobayashi.com";
      "overwrite.cli.url" = "https://cloud.home.yutakobayashi.com";
      # Keep existing local users, their attributes and permissions. OIDC only
      # authenticates them; it must not create a second account or sync groups.
      user_oidc.auto_provision = false;
      "ratelimit.protection.enabled" = false;
    };
  };

  sops.secrets.oidc-nextcloud-client-secret = {
    owner = "nextcloud";
    restartUnits = [ "nextcloud-setup.service" ];
  };

  systemd.services = {
    # Upsert by provider identifier after the upstream setup enabled user_oidc.
    nextcloud-setup.script = lib.mkAfter ''
      ${lib.getExe config.services.nextcloud.occ} user_oidc:provider pocket-id \
        --clientid nextcloud \
        --clientsecret-file ${config.sops.secrets.oidc-nextcloud-client-secret.path} \
        --discoveryuri https://id.yutakobayashi.com/.well-known/openid-configuration \
        --scope "openid profile email" \
        --unique-uid 0 --mapping-uid preferred_username \
        --mapping-email email --mapping-display-name name --group-provisioning 0 \
        --no-interaction --quiet
      ${lib.getExe config.services.nextcloud.occ} config:app:set user_oidc \
        allow_multiple_user_backends --value=1 --type=string --quiet
    '';
    nextcloud-update-db.environment.NEXTCLOUD_CONFIG_DIR = "${config.services.nextcloud.datadir}/config";
    nextcloud-setup.unitConfig.RequiresMountsFor = [
      config.services.nextcloud.datadir
    ];
    phpfpm-nextcloud.unitConfig.RequiresMountsFor = [
      config.services.nextcloud.datadir
    ];
    nextcloud-cron.unitConfig.RequiresMountsFor = [
      config.services.nextcloud.datadir
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.nextcloud = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`cloud.home.yutakobayashi.com`)";
      service = "nextcloud";
      tls.certResolver = "letsencrypt";
    };
    services.nextcloud.loadBalancer.servers = [ { url = "http://localhost:8081"; } ];
  };
}
