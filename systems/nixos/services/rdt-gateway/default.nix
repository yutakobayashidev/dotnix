{
  config,
  inputs,
  pkgs,
  ...
}:
let
  packages = inputs.rdt-gateway.packages.${pkgs.stdenv.hostPlatform.system};
  gatewayPort = 18791;
  gatewayUrl = "http://127.0.0.1:${toString gatewayPort}";
  tunnelServiceName = "tunnel-client-rdt-gateway";
  tunnelCredentialName = "control-plane-api-key";
in
{
  imports = [
    inputs.rdt-gateway.nixosModules.default
  ];

  environment.systemPackages = [ packages.rdt-cli ];
  environment.variables.RDT_GATEWAY_URL = gatewayUrl;

  sops.secrets.openai-tunnel-api-key = {
    sopsFile = ../../../../secrets/openai-tunnel.yaml;
  };

  services = {
    rdt-gateway = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = gatewayPort;
    };

    openai-tunnel-client.instances.rdt-gateway = {
      enable = true;
      environment.RDT_GATEWAY_URL = gatewayUrl;
      settings = {
        config_version = 1;
        control_plane = {
          tunnel_id = "tunnel_6ac3cceb47b08191a79db514d1cb89a1";
          # Resolve the credential directly, matching the other tunnel instances.
          api_key = "file:/run/credentials/${tunnelServiceName}.service/${tunnelCredentialName}";
        };
        health.listen_addr = "127.0.0.1:18792";
        admin_ui.open_browser = false;
        mcp.commands = [
          {
            channel = "main";
            command = "${packages.rdt-mcp}/bin/rdt-mcp";
          }
        ];
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.rdt-gateway = {
        entryPoints = [ "websecure" ];
        rule = "Host(`rdt.home.yutakobayashi.com`)";
        service = "rdt-gateway";
        tls.certResolver = "letsencrypt";
      };
      rdt-gateway.loadBalancer.servers = [
        { url = gatewayUrl; }
      ];
    };
  };

  systemd.services.${tunnelServiceName} = {
    after = [ "rdt-gateway.service" ];
    wants = [ "rdt-gateway.service" ];
    serviceConfig.LoadCredential = [
      "${tunnelCredentialName}:${config.sops.secrets.openai-tunnel-api-key.path}"
    ];
  };
}
