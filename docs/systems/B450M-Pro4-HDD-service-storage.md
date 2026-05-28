# B450M-Pro4 HDD Service Storage Notes

These notes record the May 2026 migration for using the 3TB HDD as bulk storage
for Nextcloud and ArchiveBox while preserving the existing NTFS data.

## Goal

- Keep the existing NTFS data as a migration source.
- Shrink the NTFS partition instead of wiping the disk.
- Create one new btrfs partition for Linux service data.
- Put service data under separate directories:

  ```text
  /srv/bulk/nextcloud/data
  /srv/bulk/archivebox/data
  ```

Do not put active Nextcloud or ArchiveBox data directly on the NTFS partition.
NTFS is useful as a temporary migration source, but Linux-native service data
should live on btrfs.

## Observed Disk State

The HDD was identified as:

```text
/dev/sda  ST3000DM007-1WY10G  WFN1XY5V  2.7T
```

Partition layout before changes:

```text
/dev/sda1  16M   Microsoft reserved partition
/dev/sda2  2.7T  NTFS  label=HDD  uuid=8420B13020B12A56
```

`/dev/sda2` was mounted read-only at `/tmp/hdd-sda2`. It contained about 485GB
of existing Windows-era data, with about 2.3TB free.

`ArchiveBox` currently binds this path into the container:

```nix
"/mnt/usb/services/archivebox/data:/data"
```

There was no declarative `/mnt/usb` mount in this repository.

## Completed Safety Checks

Tools were entered with:

```sh
nix shell nixpkgs#ntfs3g nixpkgs#parted nixpkgs#gptfdisk nixpkgs#btrfs-progs nixpkgs#smartmontools
```

SMART health passed:

```text
sudo smartctl -H /dev/sda
SMART overall-health self-assessment test result: PASSED
```

Partition table backup succeeded:

```sh
sudo sfdisk -d /dev/sda | sudo tee /persist/sda.partition-table.before.sfdisk >/dev/null
sudo sgdisk --backup=/persist/sda.gpt.before.bin /dev/sda
```

The NTFS resize checks passed:

```sh
sudo ntfsresize --check /dev/sda2
sudo ntfsresize --info /dev/sda2
```

Observed `ntfsresize --info` values:

```text
Current volume size: 3000574669312 bytes (3000575 MB)
Current device size: 3000574672896 bytes (3000575 MB)
Space in use       : 519707 MB (17.3%)
Minimum resize     : 519707 MB
```

The planned NTFS size was 1200GB, leaving substantial headroom over the 520GB
minimum.

Dry-run shrink to 1200GB succeeded:

```sh
sudo umount /tmp/hdd-sda2
sudo ntfsresize --no-action --size 1200G /dev/sda2
```

Important dry-run output:

```text
Needed relocations : 0 (0 MB)
The read-only test run ended successfully.
```

## Stop Condition Found

The `ntfsclone --metadata` safety backup failed:

```sh
sudo ntfsclone --metadata --output /persist/sda2.ntfs-metadata.before.img /dev/sda2
```

The error included:

```text
The disk contains an unclean file system (0, 0).
Metadata kept in Windows cache, refused to mount.
ERROR(1): Opening '/persist/sda2.ntfs-metadata.before.img' as NTFS failed
```

Follow-up probe confirmed the important state:

```sh
sudo ntfs-3g.probe --readwrite /dev/sda2
# exit 14, refused with "Metadata kept in Windows cache"

sudo ntfs-3g.probe --readonly /dev/sda2
# exit 0
```

This means the NTFS partition is readable, but not considered safe for
read-write NTFS access from Linux. Do not run the real `ntfsresize --size ...`
while this condition remains.

## Next Safe Step

Preferred fix:

1. Boot Windows PE or a Windows installer USB.
2. Run `chkdsk /f` against the NTFS volume.
3. Fully shut down.
4. Boot back into NixOS.
5. Re-run:

   ```sh
   sudo ntfs-3g.probe --readwrite /dev/sda2
   sudo ntfsresize --check /dev/sda2
   sudo ntfsresize --no-action --size 1200G /dev/sda2
   ```

Only proceed if the read-write probe exits `0` and the dry-run still succeeds.

## Windows-Side Shrink

Windows was used to clean and shrink the NTFS volume. This avoided writing to an
unclean NTFS volume from Linux.

1. Boot the Windows environment.
2. Open Command Prompt.
3. Identify the volume letter for the `HDD` NTFS volume:

   ```cmd
   diskpart
   list volume
   exit
   ```

4. Run `chkdsk /f` against that volume. Replace `D:` with the actual drive
   letter:

   ```cmd
   chkdsk D: /f
   ```

5. Shrink the NTFS volume from Windows. The target was to leave about 1TB for
   the NTFS migration source:

   ```cmd
   diskpart
   list volume
   select volume <HDD volume number>
   shrink desired=1800000
   exit
   ```

   Do not run `delete`, `clean`, or `format` in `diskpart`.

6. Fully shut down Windows. Do not hibernate.
7. Boot back into NixOS and verify:

   ```sh
   lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,PARTLABEL,PARTUUID,MOUNTPOINTS /dev/sda
   sudo ntfs-3g.probe --readwrite /dev/sda2
   echo $?
   sudo ntfsresize --check /dev/sda2
   ```

Verified result after booting back into NixOS:

- `/dev/sda2` is about 1TB.
- There was about 1.7TB of free space after `/dev/sda2`.
- `ntfs-3g.probe --readwrite /dev/sda2` exited `0`.
- `ntfsresize --check /dev/sda2` reported no errors.

After Windows has already shrunk the NTFS volume, do not run
`ntfsresize --size ...` from Linux. Only create the new btrfs partition in the
remaining free space:

```sh
sudo parted /dev/sda
```

Inside `parted`:

```text
print free
mkpart primary btrfs <free-space-start> 100%
quit
```

Then format the new partition:

```sh
sudo partprobe /dev/sda
sudo mkfs.btrfs -L bulk /dev/sda3
```

Completed result:

```text
/dev/sda3  btrfs  label=bulk  uuid=b51f01a3-5afd-4439-b5a0-e55503e2ebc7
```

An `@bulk` btrfs subvolume was created and service directories were prepared:

```sh
sudo mkdir -p /mnt/bulk
sudo mount /dev/disk/by-label/bulk /mnt/bulk
sudo btrfs subvolume create /mnt/bulk/@bulk
sudo umount /mnt/bulk

sudo mount -o subvol=@bulk,compress=zstd:1,noatime /dev/disk/by-label/bulk /mnt/bulk
sudo mkdir -p /mnt/bulk/nextcloud/data /mnt/bulk/archivebox/data
sudo umount /mnt/bulk
```

Linux-only fallback considered during planning:

```sh
sudo ntfsfix /dev/sda2
```

`ntfsfix` is not a full replacement for Windows `chkdsk /f`, so Windows-side
repair was preferred.

Final layout:

```text
/dev/sda1  Microsoft reserved partition
/dev/sda2  NTFS, about 1TB, existing migration source
/dev/sda3  btrfs, remaining space, label=bulk
```

Then mount the btrfs partition at `/srv/bulk` and move service data there.

## NixOS Configuration

The B450M-Pro4 host mounts the btrfs subvolume at `/srv/bulk`:

```nix
fileSystems."/srv/bulk" = {
  device = "/dev/disk/by-label/bulk";
  fsType = "btrfs";
  options = [
    "subvol=@bulk"
    "compress=zstd:1"
    "noatime"
  ];
};
```

Nextcloud and Immich keep the NixOS module default state locations and mount
dedicated bulk subvolumes there:

```nix
fileSystems."/var/lib/nextcloud" = {
  device = "/dev/disk/by-label/bulk";
  fsType = "btrfs";
  options = [
    "subvol=@bulk/nextcloud"
    "compress=zstd:1"
    "noatime"
  ];
};

fileSystems."/var/lib/immich" = {
  device = "/dev/disk/by-label/bulk";
  fsType = "btrfs";
  options = [
    "subvol=@bulk/immich"
    "compress=zstd:1"
    "noatime"
  ];
};
```

Create the subvolumes before switching:

```sh
sudo mount /dev/disk/by-label/bulk /mnt/bulk
sudo btrfs subvolume create /mnt/bulk/@bulk/nextcloud
sudo btrfs subvolume create /mnt/bulk/@bulk/immich
sudo umount /mnt/bulk
```

If `/mnt/bulk/@bulk/nextcloud` or `/mnt/bulk/@bulk/immich` already exists as a
regular directory, move or remove it before creating the subvolume.

Nextcloud uses:

```text
/var/lib/nextcloud
```

Immich uses:

```text
/var/lib/immich
```

ArchiveBox uses:

```text
/srv/bulk/archivebox/data
```
