_:

{
  flake.modules.nixos.tibo-reset-monitor =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.tibo-reset-monitor;
    in
    {
      options.my.services.tibo-reset-monitor = {
        enable = lib.mkEnableOption "Codex reset announcement notifications";
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.tibo-reset-monitor;
          description = "Codex Resets API monitor package.";
        };
        webhookFile = lib.mkOption {
          type = lib.types.str;
          description = "Runtime file containing the Discord webhook URL.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.tibo-reset-monitor = {
          description = "Codex reset announcement monitor";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe cfg.package} --state-dir /var/lib/tibo-reset-monitor --webhook-file %d/discord-webhook";
            DynamicUser = true;
            StateDirectory = "tibo-reset-monitor";
            StateDirectoryMode = "0700";
            WorkingDirectory = "/var/lib/tibo-reset-monitor";
            LoadCredential = [ "discord-webhook:${cfg.webhookFile}" ];
            UMask = "0077";
            TimeoutStartSec = "4min";
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            RestrictSUIDSGID = true;
            RestrictAddressFamilies = [
              "AF_UNIX"
              "AF_INET"
              "AF_INET6"
            ];
          };
        };
        systemd.timers.tibo-reset-monitor = {
          description = "Poll Codex reset announcements every five minutes";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1m";
            OnUnitInactiveSec = "5m";
            RandomizedDelaySec = "15s";
          };
        };
      };
    };
}
