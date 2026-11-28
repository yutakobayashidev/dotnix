{
  config,
  lib,
  pkgs,
  ...
}:

let
  backup = config.services.restic.backups.livesync-backup;
  host = config.networking.hostName;
  target = ''job="node",host="${host}"'';
  metric = "livesync_backup_latest_snapshot_timestamp_seconds";
  snapshot = "${metric}{${target}}";
  textfile = "/var/lib/node-exporter-textfile/${metric}.prom";
  checkSnapshot = pkgs.writeShellApplication {
    name = "livesync-backup-snapshot";
    runtimeInputs = [
      backup.package
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      latest=$(
        restic ${
          lib.escapeShellArgs (
            lib.concatMap (option: [
              "-o"
              option
            ]) backup.extraOptions
          )
        } \
          --no-lock --no-cache snapshots --json --latest 1 --group-by "" \
          --host ${lib.escapeShellArg host} ${
            lib.escapeShellArgs (
              lib.concatMap (path: [
                "--path"
                path
              ]) backup.paths
            )
          } |
          jq -r 'if . == null or . == [] then empty else .[0].time // error("Missing snapshot timestamp") end'
      )
      timestamp=0
      if [[ -n "$latest" ]]; then
        timestamp=$(date --date="$latest" +%s)
      fi

      # Publish an atomic update and keep the last observation on query errors.
      tmp=$(mktemp "$STATE_DIRECTORY/metrics.XXXXXX")
      trap 'rm -f "$tmp"' EXIT
      printf '# TYPE %s gauge\n%s %s\n' ${metric} ${metric} "$timestamp" > "$tmp"
      chmod 0644 "$tmp"
      mv -T "$tmp" ${lib.escapeShellArg textfile}
    '';
  };
in
{
  systemd.services.livesync-backup-snapshot = {
    description = "Read the latest LiveSync snapshot from R2";
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "sops-install-secrets.service"
    ];
    environment = {
      RESTIC_REPOSITORY = backup.repository;
      RESTIC_PASSWORD_FILE = backup.passwordFile;
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe checkSnapshot;
      EnvironmentFile = backup.environmentFile;
      StateDirectory = "livesync-backup-snapshot";
      StateDirectoryMode = "0700";
      TimeoutStartSec = "2min";
    };
  };

  systemd.timers.livesync-backup-snapshot = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnActiveSec = "1min";
      OnCalendar = "*-*-* *:00/15:00";
      AccuracySec = "15s";
    };
  };

  services.vmalert.instances.main.rules.groups = [
    {
      name = "livesync-backup";
      rules = [
        {
          alert = "LiveSyncBackupStale";
          expr = ''
            (time() - ${snapshot} >= 30 * 60 * 60)
            or
            ((up{${target}} == 1) unless on (host) ${snapshot})
          '';
          for = "5m";
          labels.severity = "warning";
          annotations = {
            summary = "LiveSync backup is stale or its status is unavailable on {{ $labels.host }}";
            description = "Check livesync-backup-snapshot.service, livesync-backup.service, and restic-backups-livesync-backup.service. The R2 repository should have a snapshot from B450M-Pro4 within the last 30 hours.";
          };
        }
      ];
    }
  ];
}
