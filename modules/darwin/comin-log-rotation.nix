{
  config,
  lib,
  ...
}:
let
  cominLog = config.launchd.daemons.comin.serviceConfig.StandardOutPath;
in
{
  config = lib.mkIf config.services.comin.enable {
    my.services.newsyslog.settings.${cominLog} = {
      count = 10;
      size = 1000;
      flags = [ "Z" ];
    };

    launchd.daemons.comin-log-rotator = {
      serviceConfig = {
        Label = "com.dotfiles.comin-log-rotator";
        WatchPaths = [ cominLog ];
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/bin/sleep 1; exec /bin/launchctl kickstart -k system/com.github.nlewo.comin"
        ];
      };
    };
  };
}
