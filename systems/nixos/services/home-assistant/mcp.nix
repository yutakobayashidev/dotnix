{ config, ... }:
let
  serviceName = "tunnel-client-home-assistant";
  secretsDir = "/var/lib/home-assistant-secrets";
  authorizationFile = "${secretsDir}/mcp-authorization";
  environmentFile = "${secretsDir}/mcp-tunnel.env";
  credentialDir = "/run/credentials/${serviceName}.service";
  authorization = "file:${credentialDir}/ha-authorization";
in
{
  services.openai-tunnel-client.instances.home-assistant = {
    enable = true;
    settings = {
      config_version = 1;
      # The tunnel ID comes from EnvironmentFile after OpenTofu creates it.
      # Use direct file references: the pinned module's apiKeyFile nests refs.
      control_plane.api_key = "file:${credentialDir}/control-plane-api-key";
      health.listen_addr = "127.0.0.1:18793";
      admin_ui.open_browser = false;
      mcp = {
        server_urls = [
          {
            channel = "main";
            url = "http://127.0.0.1:8123/api/mcp";
          }
        ];
        extra_headers.Authorization = authorization;
        discovery_extra_headers.Authorization = authorization;
      };
    };
  };

  systemd.services.${serviceName} = {
    after = [ "home-assistant.service" ];
    wants = [ "home-assistant.service" ];
    unitConfig.ConditionPathExists = [
      authorizationFile
      environmentFile
    ];
    serviceConfig = {
      EnvironmentFile = environmentFile;
      LoadCredential = [
        "control-plane-api-key:${config.sops.secrets.openai-tunnel-api-key.path}"
        "ha-authorization:${authorizationFile}"
      ];
    };
  };
}
