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
          threads = lib.mkIf daemonSupported {
            capture = true;
            capture_tools = true;
          };
        };
      };
    };
}
