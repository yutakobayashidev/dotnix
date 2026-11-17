_:

{
  flake.modules.homeManager.atuin =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      daemonSupported = config.systemd.user.enable or pkgs.stdenv.hostPlatform.isDarwin;
      # Background services do not inherit Home Manager's shell session variables.
      daemonEnvironment =
        lib.filterAttrs (
          name: _:
          builtins.elem name [
            "CLAUDE_CONFIG_DIR"
            "CODEX_HOME"
            "COPILOT_HOME"
            "PI_CODING_AGENT_DIR"
            "PI_CODING_AGENT_SESSION_DIR"
            "OPENCODE_DB"
            "OPENCODE_DISABLE_CHANNEL_DB"
          ]
        ) config.home.sessionVariables
        // {
          XDG_CONFIG_HOME = config.xdg.configHome;
          XDG_DATA_HOME = config.xdg.dataHome;
          XDG_STATE_HOME = config.xdg.stateHome;
          XDG_CACHE_HOME = config.xdg.cacheHome;
        };
      # MCP clients may run without XDG_RUNTIME_DIR. Use one configured socket path.
      daemonSocket = "${config.xdg.dataHome}/atuin/daemon.sock";
    in
    {
      programs.atuin = {
        enable = true;
        enableBashIntegration = false;
        enableZshIntegration = false;
        flags = [ "--disable-up-arrow" ];
        daemon.enable = lib.mkDefault daemonSupported;
        settings = {
          auto_sync = true;
          update_check = false;
          sync_address = "http://B450M-Pro4:8890";
          daemon.socket_path = lib.mkIf config.programs.atuin.daemon.enable daemonSocket;
          threads = lib.mkIf daemonSupported {
            capture = true;
            capture_tools = true;
          };
        };
      };

      systemd.user.services.atuin-daemon =
        lib.mkIf (config.programs.atuin.daemon.enable && config.systemd.user.enable)
          {
            Service.Environment = lib.mapAttrsToList (name: value: "${name}=${value}") daemonEnvironment;
          };

      systemd.user.sockets.atuin-daemon =
        lib.mkIf (config.programs.atuin.daemon.enable && config.systemd.user.enable)
          {
            Socket.ListenStream = lib.mkForce daemonSocket;
          };

      launchd.agents.atuin-daemon =
        lib.mkIf (config.programs.atuin.daemon.enable && pkgs.stdenv.hostPlatform.isDarwin)
          {
            config.EnvironmentVariables = daemonEnvironment;
          };
    };
}
