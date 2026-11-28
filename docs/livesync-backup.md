# LiveSync vault backup

UM790-Pro runs the upstream Self-hosted LiveSync CLI daemon as
`livesync-backup.service`. It polls the remote every five minutes and keeps a
persistent replica at `/var/lib/livesync-backup/vault`. Only the daemon should
write there. Local changes are synchronised back to the remote.

`restic-backups-livesync-backup.timer` runs daily at 04:00 local time and two
minutes after activation. Restic checks for a recent successful replication
from the running daemon before reading the vault. It keeps 14 daily, 8 weekly,
and 12 monthly encrypted snapshots at `livesync-backup/UM790-Pro` in the
dedicated Cloudflare R2 bucket managed by tofu-configuration.

The first start uses `fetch --force` to populate the replica before the daemon
starts. The daemon refuses to start with an empty replica. An interrupted Fetch
resumes with the same client state. The backup covers notes and attachments available through
LiveSync. It omits server-side revision history and files excluded from
synchronisation.

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
journalctl -u livesync-backup -u restic-backups-livesync-backup
```

To restore to a separate directory:

```sh
sudo install -d -m 0700 /var/lib/livesync-restore
sudo restic-livesync-backup restore latest --target /var/lib/livesync-restore
```

The restored vault is under
`/var/lib/livesync-restore/var/lib/livesync-backup/vault/`. Inspect it
before syncing it to a fresh Worker.

If the remote was deliberately rebuilt and locks this device out, stop the
daemon, move the replica aside, and request a fresh Fetch:

```sh
sudo systemctl stop livesync-backup
sudo mv /var/lib/livesync-backup/vault /var/lib/livesync-backup/vault.before-fetch
sudo rm /var/lib/livesync-backup/daemon-initialised
sudo systemctl start livesync-backup
```
