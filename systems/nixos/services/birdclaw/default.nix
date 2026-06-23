{ inputs, ... }:

let
  domain = "birdclaw.home.yutakobayashi.com";
  port = 3005;
in

{
  imports = [
    inputs.nur-packages.nixosModules.birdclaw
  ];

  services.birdclaw = {
    enable = true;
    host = "127.0.0.1";
    inherit port;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.birdclaw = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "birdclaw";
      tls.certResolver = "letsencrypt";
    };
    services.birdclaw.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString port}"; }
    ];
  };
}
