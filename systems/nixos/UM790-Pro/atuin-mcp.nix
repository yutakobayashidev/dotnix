{
  config,
  lib,
  username,
  ...
}:
let
  service = "tunnel-client-atuin-mcp";
  home = config.home-manager.users.${username};
  atuin = home.programs.atuin.package;
in
{
  services.openai-tunnel-client.instances.atuin-mcp = {
    enable = true;
    user = username;
    group = "users";
    environment = {
      XDG_CONFIG_HOME = home.xdg.configHome;
      XDG_DATA_HOME = home.xdg.dataHome;
      XDG_STATE_HOME = "/var/lib/atuin-mcp";
      XDG_CACHE_HOME = "/var/cache/atuin-mcp";
    };
    settings = {
      config_version = 1;
      control_plane = {
        # openai_mcp_tunnel.atuin_mcp in tofu-configuration.
        tunnel_id = "tunnel_6b05de9520148191b5e9dc1c08aa1c8e";
        api_key = "file:/run/credentials/${service}.service/control-plane-api-key";
      };
      health.listen_addr = "127.0.0.1:18796";
      admin_ui.open_browser = false;
      mcp.commands = [
        {
          channel = "main";
          command = "${lib.getExe atuin} mcp";
        }
      ];
    };
    serviceConfig = {
      ProtectHome = "tmpfs";
      BindReadOnlyPaths = [ "${home.xdg.configHome}/atuin" ];
      # Atuin needs write access for SQLite metadata and WAL files.
      BindPaths = [ "${home.xdg.dataHome}/atuin" ];
      StateDirectory = "atuin-mcp";
      StateDirectoryMode = "0700";
      CacheDirectory = "atuin-mcp";
      CacheDirectoryMode = "0700";
    };
  };

  systemd.services.${service} = {
    after = [ "home-manager-${username}.service" ];
    serviceConfig.LoadCredential = [
      "control-plane-api-key:${config.sops.secrets.openai-tunnel-api-key.path}"
    ];
  };
}
