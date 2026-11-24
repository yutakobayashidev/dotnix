{
  config,
  lib,
  pkgs,
  ...
}:

let
  configDir = config.services.home-assistant.configDir;
  stage = "/var/lib/home-assistant-backup";
  # One repository per host and service, as in natsukium/dotfiles: restic
  # forget --prune locks its whole repository, and a restore only wants one
  # service. tofu-configuration owns the bucket and its scoped token.
  repository = "s3:https://8b50ea3379fb9efb39ecef76cfcaa04a.r2.cloudflarestorage.com/restic-backup/${config.networking.hostName}/home-assistant";
in
{
  # The repository password, and AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
  # for the restic-backup bucket. thinkpad-home can decrypt the file too, which
  # keeps a recovery copy of the password outside this machine.
  sops.secrets = {
    restic-password.sopsFile = ./restic.yaml;
    restic-r2-credentials.sopsFile = ./restic.yaml;
  };

  services.restic.backups.home-assistant = {
    # Off-site, so that losing this machine or its disks does not take the
    # backups with it.
    inherit repository;
    passwordFile = config.sops.secrets.restic-password.path;
    environmentFile = config.sops.secrets.restic-r2-credentials.path;
    # R2 has no regions, but the S3 client needs one and would otherwise ask
    # the bucket where it lives on every run.
    extraOptions = [ "s3.region=auto" ];
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
    serviceConfig.UMask = "0077";
  };
}
