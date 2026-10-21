{
  config,
  lib,
  pkgs,
  ...
}:

let
  configDir = config.services.home-assistant.configDir;
  stage = "/var/lib/home-assistant-backup";
  passwordFile = "/var/lib/home-assistant-secrets/restic-password";
in
{
  services.restic.backups.home-assistant = {
    repository = "/srv/bulk/backups/home-assistant";
    inherit passwordFile;
    initialize = true;
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      RandomizedDelaySec = "45m";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];
    paths = [
      configDir
      stage
    ];
    exclude = [
      "${configDir}/home-assistant_v2.db*"
      "${configDir}/home-assistant.log*"
      "${configDir}/.cache"
      "${configDir}/tts"
      "${configDir}/backups"
    ];
    backupPrepareCommand = ''
      #!${pkgs.runtimeShell}
      set -euo pipefail
      test -f ${configDir}/home-assistant_v2.db
      ${pkgs.coreutils}/bin/install -d -m 0700 -o hass -g hass ${stage}
      ${pkgs.coreutils}/bin/install -d -m 0700 -o hass -g hass ${stage}/recorder
      ${pkgs.util-linux}/bin/runuser -u hass -- ${lib.getExe pkgs.sqlite} \
        ${configDir}/home-assistant_v2.db ".timeout 30000" \
        ".backup '${stage}/recorder/home-assistant_v2.db'"

      # Snapshot the fabric while Matter is stopped, then resume immediately.
      # Do not restart a service that was already stopped by the operator.
      restart_matter=false
      if ${pkgs.systemd}/bin/systemctl is-active --quiet matterjs-server; then
        restart_matter=true
      fi
      trap 'if "$restart_matter"; then ${pkgs.systemd}/bin/systemctl start matterjs-server; fi' EXIT
      if "$restart_matter"; then
        ${pkgs.systemd}/bin/systemctl stop matterjs-server
      fi
      test -d /var/lib/matterjs-server
      ${pkgs.coreutils}/bin/rm -rf ${stage}/matterjs-server
      ${pkgs.coreutils}/bin/cp -aL /var/lib/matterjs-server ${stage}/matterjs-server
    '';
    backupCleanupCommand = ''
      #!${pkgs.runtimeShell}
      ${pkgs.coreutils}/bin/rm -rf ${stage}
    '';
  };

  systemd.services.restic-backups-home-assistant = {
    unitConfig = {
      RequiresMountsFor = [ "/srv/bulk" ];
      ConditionPathExists = passwordFile;
    };
    serviceConfig.UMask = "0077";
  };
}
