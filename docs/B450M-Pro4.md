# B450M-Pro4 (NixOS) Installation Guide

## First Installation

B450M-Pro4 uses LUKS encryption with Btrfs and impermanence. These steps are for a fresh install.

### Prerequisites

- NixOS installation USB
- Another machine with Nix installed
- Network connectivity on the target machine
- Strong LUKS passphrase

### 1. Boot NixOS Installer USB

```sh
sudo systemctl start NetworkManager
nmtui
```

### 2. Enable SSH Access

Run this on the target machine:

```sh
passwd
ip addr
```

### 3. Confirm Target Disk

Run this on the target machine before using nixos-anywhere or disko:

```sh
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/ | grep -E 'nvme|ata'
```

Use the disk row from `lsblk` to identify the internal drive. The installer USB
also appears as a disk, so check `MODEL`, `SERIAL`, and `SIZE` before proceeding.

If the target is not `/dev/nvme0n1`, update `systems/nixos/B450M-Pro4/disko.nix`
before running the install. For destructive disko installs, a stable `by-id`
path is safer than a kernel-assigned name:

```nix
device = "/dev/disk/by-id/nvme-...";
```

### 4. Run nixos-anywhere

Run this from another machine.

WARNING: This erases all data on the target disk. The current disko config targets `/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_250GB_S4EUNG0M204721K`.

```sh
ssh nixos@<TARGET_IP>

read -s -p "Enter LUKS passphrase: " LUKS_PASS

nix run github:nix-community/nixos-anywhere -- \
  --flake github:yutakobayashidev/dotnix#B450M-Pro4 \
  --disk-encryption-keys /tmp/luks-password <(printf '%s' "$LUKS_PASS") \
  nixos@<TARGET_IP>

unset LUKS_PASS
```

### 5. Reboot

```sh
sudo reboot
```

## Manual Installation

Use this fallback when nixos-anywhere is not available.

### 1. Clone Configuration

```sh
nix-shell -p git
git clone https://github.com/yutakobayashidev/dotnix
cd dotnix
```

### 2. Create LUKS Password File

```sh
read -s -p "Enter LUKS passphrase: " LUKS_PASS
printf '%s' "$LUKS_PASS" > /tmp/luks-password
chmod 600 /tmp/luks-password
unset LUKS_PASS
```

### 3. Run Disko

WARNING: This erases all data on `/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_250GB_S4EUNG0M204721K`.

```sh
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  ./systems/nixos/B450M-Pro4/disko.nix
```

### 4. Install NixOS

```sh
ulimit -n 65536
sudo nixos-install --flake .#B450M-Pro4 --no-root-passwd --cores 1 --max-jobs 1
```

### 5. Reboot

```sh
sudo reboot
```

## Update Configuration

After installation, apply configuration changes with:

```sh
sudo nixos-rebuild switch --flake .#B450M-Pro4 --show-trace
```

Do not run disko again on an installed system unless you intend to wipe and reinstall the target disk.
