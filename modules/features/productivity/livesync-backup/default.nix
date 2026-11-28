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
      stage = "${state}/vault";
      database = "${state}/db";
      cliImage = "ghcr.io/vrtmrz/livesync-cli:1.0.52-cli@sha256:cf9c28ca544e5e84e8825185a81032559c5503ad812c6cd66be4a714bca78a4f";
      docker = lib.getExe pkgs.docker;
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

        services.restic.backups.${name} = {
          inherit (cfg) repository passwordFile environmentFile;
          extraOptions = [ "s3.region=auto" ];
          initialize = true;
          paths = [ stage ];
          timerConfig = {
            OnCalendar = "*-*-* 04:00:00";
            OnActiveSec = "1min";
            Persistent = true;
          };
          pruneOpts = [
            "--keep-daily 14"
            "--keep-weekly 8"
            "--keep-monthly 12"
          ];
          backupPrepareCommand = ''
            #!${pkgs.runtimeShell}
            set -euo pipefail
            export PATH=${
              lib.makeBinPath [
                pkgs.coreutils
                pkgs.findutils
              ]
            }

            install -d -m 0700 ${database}
            settings=${state}/settings.json
            sourceSettings=${lib.escapeShellArg (toString cfg.settingsFile)}
            checksum="$(sha256sum < "$sourceSettings")"
            stamp=${state}/settings-source.sha256

            # Keep the CLI's saved database suffix and identity across runs.
            # A new secret can be applied once any interrupted Fetch has finished.
            if [ ! -e ${database}/.livesync/reconstruction.json ]; then
              if [ ! -s "$settings" ] || [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$checksum" ]; then
                install -m 0600 "$sourceSettings" "$settings.new"
                mv -f "$settings.new" "$settings"
                printf '%s\n' "$checksum" > "$stamp"
              fi
              rm -rf -- ${stage}
            fi
            install -d -m 0700 ${stage}

            cli() {
              ${docker} run --rm --cap-drop=ALL --security-opt=no-new-privileges \
                --mount type=bind,src=${state},dst=/data \
                --env LIVESYNC_DB_PATH=/data/db \
                ${lib.escapeShellArg cliImage} \
                --settings /data/settings.json --vault /data/vault "$@"
            }

            # Fetch rebuilds the local DB and registers a new device. Keep the
            # same DB for daily sync, then export into the empty staging path.
            initialised=${state}/initialised
            if [ ! -e "$initialised" ] || [ -e ${database}/.livesync/reconstruction.json ]; then
              cli fetch --force
            elif syncOutput="$(cli sync 2>&1)"; then
              printf '%s\n' "$syncOutput"
              cli mirror
            else
              printf '%s\n' "$syncOutput" >&2
              case "$syncOutput" in
                *"The remote database is locked and this device is not yet accepted."*)
                  cli fetch --force
                  ;;
                *) exit 1 ;;
              esac
            fi

            # An empty export cannot replace a successful backup of this vault.
            test -n "$(find ${stage} -type f -print -quit)"
            touch "$initialised"
          '';
          backupCleanupCommand = ''
            #!${pkgs.runtimeShell}
            set -eu
            # Retain files needed to resume an interrupted Fetch.
            if [ ! -e ${database}/.livesync/reconstruction.json ]; then
              ${pkgs.coreutils}/bin/rm -rf -- ${stage}
            fi
          '';
        };

        systemd.services."restic-backups-${name}" = {
          requires = [ "docker.service" ];
          after = [ "docker.service" ];
          serviceConfig = {
            StateDirectory = name;
            StateDirectoryMode = "0700";
            UMask = "0077";
          };
        };
      };
    };
}
