{ config, ... }: {
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    accelerationDevices = null;
    settings = {
      storageTemplate.enabled = true;
      passwordLogin.enabled = true;
      oauth = {
        enabled = true;
        issuerUrl = "https://id.yutakobayashi.com";
        clientId = "immich";
        clientSecret._secret = config.sops.secrets.oidc-immich-client-secret.path;
        scope = "openid profile email";
        buttonText = "Login with Pocket ID";
        autoRegister = false;
        autoLaunch = false;
      };
    };
  };

  sops.secrets.oidc-immich-client-secret.restartUnits = [ "immich-server.service" ];

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services.traefik.dynamicConfigOptions.http = {
    routers.immich = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`photos.home.yutakobayashi.com`)";
      service = "immich";
      tls.certResolver = "letsencrypt";
    };
    services.immich.loadBalancer.servers = [ { url = "http://localhost:2283"; } ];
  };
}
