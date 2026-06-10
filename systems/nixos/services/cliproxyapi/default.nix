{
  config,
  inputs,
  pkgs,
  ...
}:

let
  domain = "home.yutakobayashi.com";
  cfg = config.services.cliproxyapi;
in
{
  imports = [
    inputs.cliproxyapi.nixosModules.default
  ];

  services.cliproxyapi = {
    enable = true;
    package = inputs.cliproxyapi.packages.${pkgs.system}.cliproxyapi;
    configFile = pkgs.writeText "cliproxyapi-config.yaml" ''
      host: "127.0.0.1"
      port: ${toString cfg.port}
      api-keys:
        - "sk-proxy"
    '';
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.cliproxyapi = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`cliproxy.${domain}`)";
      service = "cliproxyapi";
      tls.certResolver = "letsencrypt";
    };
    services.cliproxyapi.loadBalancer.servers = [
      { url = "http://127.0.0.1:8317"; }
    ];
  };
}
