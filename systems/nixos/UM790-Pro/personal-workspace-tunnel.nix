{ config, username, ... }:

let
  tunnelServiceName = "tunnel-client-personal-workspace";
  tunnelCredentialName = "control-plane-api-key";
in
{
  services.openai-tunnel-client.instances.personal-workspace = {
    enable = true;
    user = username;
    group = "users";
    settings = {
      config_version = 1;
      control_plane = {
        tunnel_id = "tunnel_6ac62e4088bc8191ba2fbc6648c0171b";
        api_key = "file:/run/credentials/${tunnelServiceName}.service/${tunnelCredentialName}";
      };
      health.listen_addr = "127.0.0.1:18791";
      admin_ui.open_browser = false;
      mcp.server_urls = [
        {
          channel = "main";
          url = "http://100.91.91.87:3006/mcp";
        }
      ];
    };
  };

  systemd.services.${tunnelServiceName}.serviceConfig.LoadCredential = [
    "${tunnelCredentialName}:${config.sops.secrets.openai-tunnel-api-key.path}"
  ];
}
