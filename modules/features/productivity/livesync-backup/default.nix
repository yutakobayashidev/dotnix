_:

{
  flake.modules.nixos."livesync-backup" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.livesync-backup;
      name = "livesync-backup";
      state = "/var/lib/${name}";
      vault = "${state}/vault";
      database = "${state}/db";
      find = lib.getExe' pkgs.findutils "find";
      cliImage = "ghcr.io/vrtmrz/livesync-cli:1.0.52-cli@sha256:cf9c28ca544e5e84e8825185a81032559c5503ad812c6cd66be4a714bca78a4f";
      docker = lib.getExe pkgs.docker;
      systemctl = lib.getExe' pkgs.systemd "systemctl";
      journalctl = lib.getExe' pkgs.systemd "journalctl";
      cli = pkgs.writeShellScript "livesync-backup-cli" ''
        exec ${docker} run --rm --cap-drop=ALL --security-opt=no-new-privileges \
          --mount type=bind,src=${state},dst=/data \
          --env LIVESYNC_DB_PATH=/data/db \
          ${lib.escapeShellArg cliImage} \
          --settings /data/settings.json --vault /data/vault "$@"
      '';
    in
    {
      options.my.services.livesync-backup = {
        enable = lib.mkEnableOption "scheduled off-site backups of a Self-hosted LiveSync vault";

        settingsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the secret JSON settings for the backup's LiveSync client.";
        };

        repository = lib.mkOption {
          type = lib.types.nonEmptyStr;
          description = "Restic repository dedicated to this vault.";
        };

        passwordFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the Restic repository password.";
        };

        environmentFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the environment file with credentials for the Restic backend.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = config.virtualisation.docker.enable;
            message = "my.services.livesync-backup requires Docker to run the upstream LiveSync CLI image.";
          }
        ];

        systemd.services.${name} = {
          description = "Self-hosted LiveSync backup client";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          requires = [ "docker.service" ];
          after = [
            "network-online.target"
            "docker.service"
          ];
          path = [ pkgs.coreutils ];
          serviceConfig = {
            Type = "exec";
            ExecStart = "${cli} --verbose --interval 300 daemon";
            Restart = "on-failure";
            RestartSec = "30s";
            StateDirectory = name;
            StateDirectoryMode = "0700";
            UMask = "0077";
          };

          preStart = ''
            install -d -m 0700 ${database} ${vault}
            settings=${state}/settings.json
            sourceSettings=${lib.escapeShellArg (toString cfg.settingsFile)}
            stamp=${state}/settings-source.sha256
            initialised=${state}/daemon-initialised
            recovery=${database}/.livesync/reconstruction.json

            # Keep the CLI's saved settings and reconstruction state on restart.
            if [ ! -e "$recovery" ]; then
              checksum="$(sha256sum < "$sourceSettings")"
              if [ ! -s "$settings" ] || [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$checksum" ]; then
                install -m 0600 "$sourceSettings" "$settings"
                printf '%s\n' "$checksum" > "$stamp"
              fi
            fi
            # The old Restic job removed its export after every run. Seed the
            # filesystem before the daemon can interpret missing files as deletes.
            if [ ! -e "$initialised" ] || [ -e "$recovery" ]; then
              ${cli} fetch --force
              touch "$initialised"
            fi
            if [ -z "$(${find} ${vault} -type f -print -quit)" ]; then
              echo "Refusing to start LiveSync with an empty backup vault" >&2
              exit 1
            fi
          '';
        };

        services.restic.backups.${name} = {
          inherit (cfg) repository passwordFile environmentFile;
          extraOptions = [ "s3.region=auto" ];
          initialize = true;
          paths = [ vault ];
          timerConfig = {
            OnCalendar = "*-*-* 04:00:00";
            OnActiveSec = "2min";
            Persistent = true;
          };
          pruneOpts = [
            "--keep-daily 14"
            "--keep-weekly 8"
            "--keep-monthly 12"
          ];
          backupPrepareCommand = ''
            #!${pkgs.runtimeShell}
            set -eu
            ${systemctl} is-active --quiet ${name}.service
            invocation="$(${systemctl} show --property=InvocationID --value ${name}.service)"
            last="$(
              ${journalctl} "_SYSTEMD_INVOCATION_ID=$invocation" --since="15 minutes ago" \
                --grep='Replication completed|Initial replication (complete|failed)|Poll error' \
                --lines=1 --output=cat --no-pager --quiet
            )"
            case "$last" in
              "(Info) Replication completed" | "[Daemon] Initial replication complete") ;;
              *) echo "LiveSync has no recent successful replication" >&2; exit 1 ;;
            esac
            test -n "$(${find} ${vault} -type f -print -quit)"
          '';
        };

        systemd.services."restic-backups-${name}" = {
          after = [ "${name}.service" ];
          serviceConfig.UMask = "0077";
        };
      };
    };
}
