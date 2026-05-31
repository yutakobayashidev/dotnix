{ ... }:
{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    accelerationDevices = null;
  };

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
