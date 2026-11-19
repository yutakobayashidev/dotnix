{
  config,
  lib,
  username,
  ...
}:
let
  service = "tunnel-client-atuin-mcp";
  environmentFile = "/etc/atuin-mcp/tunnel.env";
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
      control_plane.api_key = "file:/run/credentials/${service}.service/control-plane-api-key";
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
    unitConfig.ConditionPathExists = environmentFile;
    serviceConfig = {
      EnvironmentFile = environmentFile;
      LoadCredential = [ "control-plane-api-key:${config.sops.secrets.openai-tunnel-api-key.path}" ];
    };
  };
}
