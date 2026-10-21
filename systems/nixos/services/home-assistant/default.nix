_:

{
  imports = [
    ./mcp.nix
    ./matter.nix
    ./metrics.nix
    ./backup.nix
  ];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "matter"
      "mcp_server"
    ];

    config = {
      default_config = { };
      recorder.purge_keep_days = 14;
      history = { };
      logbook = { };

      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Asia/Tokyo";
      };

    };
  };

  # Since HA 2026.8, the HTTP port is managed in the UI (default: 8123).
  networking.firewall.allowedTCPPorts = [ 8123 ];

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
      { url = "http://127.0.0.1:8123"; }
    ];
  };
}
