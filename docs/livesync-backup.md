# LiveSync vault backup

UM790-Pro runs `restic-backups-livesync-backup.timer` daily at 04:00 local
time and one minute after the timer starts. The job uses the pinned Self-hosted
LiveSync CLI image to export the vault, then backs up the files to
`livesync-backup/UM790-Pro` in the dedicated Cloudflare R2 bucket managed by
tofu-configuration. It keeps 14 daily, 8
weekly, and 12 monthly snapshots.

The CLI uses a dedicated database and settings under
`/var/lib/livesync-backup`. The first run uses `fetch --force`. Daily runs
sync that database and mirror into an empty staging directory. This keeps
the same device ID and exports the current files, including attachments.
If the remote locks the client out after a rebuild, the job fetches again.
An interrupted fetch retains its staging directory and state for the next
attempt. A failed or empty export fails the job before restic runs. The backup covers the
notes and attachments available through LiveSync. It does not include
the server's revision history or files excluded from synchronisation.

The SOPS file `secrets/livesync-backup-UM790-Pro.yaml` holds the CLI
settings, backup repository password, and R2 credentials. The ThinkPad
can decrypt the file if UM790-Pro is lost. Keep the same repository
password when rotating the R2 credentials. The bucket-scoped key comes
from the `livesync_backup_access_key_id` and
`livesync_backup_secret_access_key` outputs in tofu-configuration's
`infra/global` root.

To run a backup and list snapshots:

```sh
sudo systemctl start restic-backups-livesync-backup
sudo restic-livesync-backup snapshots
journalctl -u restic-backups-livesync-backup
```

To restore to a separate directory:

```sh
sudo install -d -m 0700 /var/lib/livesync-restore
sudo restic-livesync-backup restore latest --target /var/lib/livesync-restore
```

The restored vault is under
`/var/lib/livesync-restore/var/lib/livesync-backup/vault/`. Inspect it
before syncing it to a fresh Worker.
