{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.alloy;
  combinedConfig = lib.concatStringsSep "\n\n" (lib.attrValues cfg.configs);
  configFile = pkgs.writeText "alloy.alloy" combinedConfig;

  dataDir = "/var/lib/alloy";
  logDir = "/var/log/alloy";
in
{
  options.my.services.alloy = {
    enable = lib.mkEnableOption "Grafana Alloy log shipper";

    configs = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Alloy config snippets keyed by name. All snippets are concatenated
        into a single config file for the launchd-managed Alloy daemon.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.grafana-alloy ];

    launchd.daemons.alloy.serviceConfig = {
      Label = "com.dotnix.alloy";
      ProgramArguments = [
        (lib.getExe pkgs.grafana-alloy)
        "run"
        "--storage.path=${dataDir}"
        "${configFile}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${logDir}/alloy.log";
      StandardErrorPath = "${logDir}/alloy.err.log";
    };

    system.activationScripts.alloyDirs.text = ''
      mkdir -p ${dataDir} ${logDir}
      chmod 755 ${dataDir} ${logDir}
    '';
  };
}
