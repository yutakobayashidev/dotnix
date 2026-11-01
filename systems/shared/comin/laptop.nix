{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  services.comin = {
    buildConfirmer.mode = "manual";
    deployConfirmer.mode = "manual";
    desktop.enable = true;
  };

  # Upstream only starts the desktop client on NixOS.
  home-manager.users.${username} = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    launchd.agents.comin-desktop = {
      enable = true;
      config = {
        ProgramArguments = [
          "${lib.getExe config.services.comin.package}"
          "desktop"
        ];
        EnvironmentVariables.PATH = "/usr/bin:/bin";
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
      };
    };
  };
}
