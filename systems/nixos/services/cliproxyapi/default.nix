{
  config,
  inputs,
  pkgs,
  ...
}:

let
  domain = "home.yutakobayashi.com";
in
{
  imports = [
    inputs.cliproxyapi.nixosModules.default
  ];

  services.cliproxyapi = {
    enable = true;
    package = inputs.cliproxyapi.packages.${pkgs.system}.cliproxyapi;
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
