{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  comin = config.services.comin.package;
  notifier = pkgs.writeShellApplication {
    name = "comin-confirmation-notifier";
    runtimeInputs = [
      comin
      pkgs.jq
      pkgs.coreutils
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.libnotify;
    text = builtins.readFile ./notify-confirmation.sh;
  };
in
{
  services.comin = {
    buildConfirmer.mode = "manual";
    deployConfirmer.mode = "manual";
    desktop.enable = true;
  };

  home-manager.users.${username} = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.comin-confirmation-notifier = {
        Unit = {
          Description = "Comin pending approval notifications";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe notifier} linux";
          Restart = "on-failure";
          RestartSec = 10;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      # Upstream only wires desktop.enable to a service on NixOS.
      launchd.agents = {
        comin-desktop = {
          enable = true;
          config = {
            ProgramArguments = [
              "${lib.getExe comin}"
              "desktop"
            ];
            EnvironmentVariables.PATH = "/usr/bin:/bin";
            RunAtLoad = true;
            KeepAlive = true;
            ThrottleInterval = 30;
          };
        };
        comin-confirmation-notifier = {
          enable = true;
          config = {
            ProgramArguments = [
              "${lib.getExe notifier}"
              "darwin"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            ThrottleInterval = 30;
          };
        };
      };
    })
  ];
}
