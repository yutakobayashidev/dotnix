{ config, ... }:

{
  services.home-assistant = {
    enable = true;
    openFirewall = true;

    config = {
      default_config = { };

      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Asia/Tokyo";
      };

      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.home-assistant = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`ha.home.yutakobayashi.com`)";
      service = "home-assistant";
      tls.certResolver = "letsencrypt";
    };
    services.home-assistant.loadBalancer.servers = [
      { url = "http://localhost:${toString config.services.home-assistant.config.http.server_port}"; }
    ];
  };
}
