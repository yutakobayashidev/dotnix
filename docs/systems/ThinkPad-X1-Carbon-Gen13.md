# ThinkPad X1 Carbon Gen 13 (NixOS) Installation Guide

This host dual-boots Windows and NixOS. NixOS uses an existing EFI System Partition (ESP), a dedicated LUKS partition, Btrfs subvolumes, and impermanence. Disko does not manage the GPT partition table for this host.

## Before You Start

- Back up important Windows data and the BitLocker recovery key.
- Keep Windows installed and bootable.
- Temporarily disable Secure Boot in UEFI. It is enabled after the first successful NixOS boot.
- Prepare the [custom NixOS installer ISO](../installer-iso.md) on a USB drive.
- Choose a strong LUKS passphrase.
- Keep an existing machine that can decrypt `secrets/default.yaml` available while installing.

> [!WARNING]
> `destroy = false` prevents disko from rebuilding the partition table, but it does not make an incorrect NixOS PARTUUID safe. The selected NixOS partition is formatted as LUKS. Verify both PARTUUIDs before running disko.

## 1. Prepare Partitions in Windows

Use Disk Management to shrink the Windows volume and create a primary partition for NixOS in the resulting unallocated space. Do not format it and do not assign a drive letter.

The existing EFI System Partition is shared by Windows and NixOS. Do not create or format another ESP.

Open PowerShell as Administrator and identify the disk:

```powershell
Get-Disk |
  Format-Table Number, FriendlyName, SerialNumber, PartitionStyle, Size
```

List its GPT partitions, replacing `0` with the target disk number:

```powershell
Get-CimInstance `
  -Namespace ROOT/Microsoft/Windows/Storage `
  -ClassName MSFT_Partition |
  Where-Object DiskNumber -eq 0 |
  Select-Object DiskNumber, PartitionNumber, DriveLetter, Type, GptType, Guid,
    @{Name="SizeGiB"; Expression={[math]::Round($_.Size / 1GB, 2)}} |
  Format-Table -AutoSize
```

Record the `Guid` values for:

- ESP: `GptType` is `c12a7328-f81f-11d2-ba4b-00a0c93ec93b`.
- NixOS: the unformatted partition created for NixOS.

Use the partition `Guid`, not `GptType`, the disk GUID, or a filesystem UUID.

## 2. Set the PARTUUIDs

Boot the NixOS installer with Secure Boot disabled, connect to the network, and clone this repository:

```sh
nix shell nixpkgs#git -c git clone https://github.com/yutakobayashidev/dotnix.git
cd dotnix
```

Confirm the identifiers seen by Linux:

```sh
lsblk -o NAME,SIZE,FSTYPE,PARTTYPE,PARTUUID,MOUNTPOINTS
sudo blkid
```

Confirm that `systems/nixos/ThinkPad-X1-Carbon-Gen13/disko.nix` contains the same identifiers. Update them if the disk has been repartitioned:

```nix
espPart = "/dev/disk/by-partuuid/<ESP_PARTUUID>";
nixosPart = "/dev/disk/by-partuuid/<NIXOS_PARTUUID>";
```

Before continuing, verify that each path resolves to the intended partition:

```sh
readlink -f /dev/disk/by-partuuid/<ESP_PARTUUID>
readlink -f /dev/disk/by-partuuid/<NIXOS_PARTUUID>
lsblk -o NAME,SIZE,FSTYPE,PARTUUID,MOUNTPOINTS
```

The ESP should already contain a FAT filesystem. The NixOS partition must be the partition that may be encrypted and formatted.

## 3. Create the LUKS Password File

The installer password file at `/tmp/luks-password` is an explicit exception to the repository's general secret-storage rule. It exists only in the installer environment and is not copied into the installed system.

```sh
read -s -p "Enter LUKS passphrase: " LUKS_PASS
printf '%s' "$LUKS_PASS" | sudo tee /tmp/luks-password >/dev/null
sudo chmod 600 /tmp/luks-password
unset LUKS_PASS
```

## 4. Format and Mount the NixOS Partition

Run only the `format,mount` stages. Do not add `destroy`; this host shares its disk with Windows.

```sh
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode format,mount \
  ./systems/nixos/ThinkPad-X1-Carbon-Gen13/disko.nix
```

Confirm the result:

```sh
findmnt -R /mnt
lsblk -o NAME,SIZE,FSTYPE,PARTUUID,MOUNTPOINTS
sudo cryptsetup status cryptroot
```

The expected layout is:

- `/boot`: existing Windows ESP
- `/dev/mapper/cryptroot`: LUKS container on the NixOS partition
- Btrfs subvolumes: `@root`, `@home`, `@nix`, `@persist`, `@log`, and `@swap`
- 32 GiB swapfile in `@swap`

## 5. Register the ThinkPad SOPS Identity

This host uses its persistent SSH host key as its SOPS identity. The shared NixOS configuration reads `/etc/ssh/ssh_host_ed25519_key`, and impermanence persists that path from `/persist/etc/ssh`.

Generate the key directly in its final persistent location. Do not place the private key in `/tmp` or the repository:

```sh
sudo install -d -m 700 /mnt/persist/etc/ssh
sudo ssh-keygen \
  -t ed25519 \
  -f /mnt/persist/etc/ssh/ssh_host_ed25519_key \
  -N ""
sudo chmod 600 /mnt/persist/etc/ssh/ssh_host_ed25519_key
```

Convert the public key to its age recipient:

```sh
sudo cat /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

On an existing machine that can decrypt the repository secrets:

1. Add the resulting `age1...` value to `.sops.yaml` as the ThinkPad key.
2. Add the ThinkPad key to the `^secrets/.*$` creation rule.
3. Re-encrypt the shared secret file:

   ```sh
   sops updatekeys secrets/default.yaml
   ```

4. Commit and push `.sops.yaml` and `secrets/default.yaml`.

The installer cannot perform `sops updatekeys` using only the new ThinkPad key because that key cannot decrypt the existing file yet. Pull the updated files on the ThinkPad:

```sh
git pull
```

Verify that the persistent SSH host key can decrypt the updated secret without writing plaintext to disk:

```sh
sudo env \
  SOPS_AGE_SSH_PRIVATE_KEY_FILE=/mnt/persist/etc/ssh/ssh_host_ed25519_key \
  sops --decrypt secrets/default.yaml >/dev/null
```

The shared configuration also has `sops.age.generateKey = true`, but a newly generated age key is not automatically added to `.sops.yaml`. Do not rely on it to bootstrap this host.

## 6. Install NixOS

The initial configuration uses systemd-boot and leaves Lanzaboote disabled.

Install from the current checkout:

```sh
sudo nixos-install \
  --flake .#ThinkPad-X1-Carbon-Gen13 \
  --no-root-passwd
```

Remove the installer-only password file and reboot:

```sh
sudo rm /tmp/luks-password
sudo swapoff /mnt/.swapvol/swapfile 2>/dev/null || true
sudo umount -R /mnt
sudo reboot
```

Confirm that both NixOS and Windows boot while Secure Boot remains disabled.

## 7. Enable Secure Boot After the First Boot

Keep Secure Boot disabled while completing this section. In UEFI, clear the Secure Boot keys or select the option that puts the firmware into Setup Mode. Keep the BitLocker recovery key available because changing Secure Boot keys can trigger recovery.

Check that Setup Mode is enabled:

```sh
sudo nix shell nixpkgs#sbctl -c sbctl status
```

Clone the configuration into your normal working directory:

```sh
nix shell nixpkgs#git -c git clone https://github.com/yutakobayashidev/dotnix.git
cd dotnix
```

Confirm the ESP and NixOS PARTUUIDs in `systems/nixos/ThinkPad-X1-Carbon-Gen13/disko.nix` before rebuilding.

Create the signing keys directly in their final persistent location:

```sh
sudo mkdir -p /var/lib/sbctl
sudo nix shell nixpkgs#sbctl -c sbctl create-keys
sudo chmod -R go-rwx /var/lib/sbctl
```

Back up `/var/lib/sbctl` to an encrypted external volume and record that volume as the recovery location. Do not copy the private keys to `/tmp` or this repository. For example:

```sh
sudo cp -a /var/lib/sbctl /run/media/$USER/<ENCRYPTED_VOLUME>/ThinkPad-X1-Carbon-Gen13-sbctl
```

Change the host configuration:

```nix
ext.security.secureboot.enable = true;
```

Apply it from the repository checkout:

```sh
sudo nixos-rebuild switch --flake .#ThinkPad-X1-Carbon-Gen13
sudo sbctl verify
```

Enroll the generated keys together with Microsoft's keys so Windows remains bootable:

```sh
sudo sbctl enroll-keys --microsoft
sudo sbctl status
```

Reboot into UEFI, enable Secure Boot, and then verify both operating systems. In NixOS:

```sh
bootctl status
sudo sbctl status
sudo sbctl verify
```

### Secure Boot Key Recovery

If `/var/lib/sbctl` is lost, keep Secure Boot disabled, restore the backup, and rebuild before attempting to enable Secure Boot again:

```sh
sudo mkdir -p /var/lib/sbctl
sudo cp -a /run/media/$USER/<ENCRYPTED_VOLUME>/ThinkPad-X1-Carbon-Gen13-sbctl/. /var/lib/sbctl/
sudo chmod -R go-rwx /var/lib/sbctl
sudo nixos-rebuild switch --flake .#ThinkPad-X1-Carbon-Gen13
```

## Impermanence

The `@root` subvolume is replaced with a blank subvolume during early boot. Old roots are retained for seven days under `@old_roots`.

Persistent state includes:

- `/home`
- `/nix`
- `/persist`
- `/var/log`
- `/etc/NetworkManager/system-connections`
- `/etc/nixos`
- `/etc/ssh`
- `/var/lib`
- `/etc/machine-id`

Store additional machine state under `/persist` or add it to `modules/profiles/nixos/impermanence.nix` before relying on it across reboots.

## Updating the Configuration

```sh
sudo nixos-rebuild switch --flake .#ThinkPad-X1-Carbon-Gen13 --show-trace
```

For maintenance of an existing installation, use disko's `mount` mode only. Do not run `format` again unless reinstalling the NixOS partition intentionally.

## References

- [disko](https://github.com/nix-community/disko)
- [Lanzaboote Quick Start](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)
- [sbctl](https://github.com/Foxboron/sbctl)
