{
  config,
  inputs,
  lib,
  ...
}:

let
  builders = [
    "UM790-Pro"
    "M2-MacBook-Air"
  ];
  servers = [
    "B450M-Pro4"
    "pi5"
  ];
  linuxMachines = inputs.self.outputs.nixosConfigurations;
  darwinMachines = inputs.self.outputs.darwinConfigurations;
  targetsFor =
    hosts:
    lib.mapAttrsToList (
      name: value:
      let
        listenAddress = value.config.services.prometheus.exporters.node.listenAddress;
        inherit (value.config.services.prometheus.exporters.node) port;
        host =
          if name == config.networking.hostName then
            (if listenAddress == "" then "127.0.0.1" else listenAddress)
          else
            name;
      in
      "${host}:${toString port}"
    ) (lib.filterAttrs (name: _: lib.elem name hosts) (linuxMachines // darwinMachines));
in

{
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            labels.role = "builders";
            targets = targetsFor builders;
          }
          {
            labels.role = "servers";
            targets = targetsFor servers;
          }
        ];
      }
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.prometheus = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`prometheus.home.yutakobayashi.com`)";
      service = "prometheus";
      tls.certResolver = "letsencrypt";
    };
    services.prometheus.loadBalancer.servers = [ { url = "http://127.0.0.1:9090"; } ];
  };
}
