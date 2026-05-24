# Ventoy NixOS Minimal USB Guide

This guide creates a Ventoy USB drive that boots the official NixOS Minimal ISO.

## Target Device Check

List block devices before writing anything:

```sh
lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,VENDOR,TRAN,HOTPLUG,RM,TYPE,FSTYPE,LABEL,MOUNTPOINTS
```

In the recorded setup, the USB stick was:

```text
/dev/sda  14.5G  USB Flash Disk  BUFFALO  TRAN=usb  HOTPLUG=1  RM=1
```

The internal disk was `/dev/nvme0n1`, so `/dev/sda` was the external BUFFALO USB stick.

## Install Ventoy

Ventoy is available from `nixpkgs#ventoy-full`, but nixpkgs marks it as unfree and insecure because it contains bundled binary blobs. Allow it only for this one command:

```sh
env NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 \
  nix shell --impure nixpkgs#ventoy-full -c sudo ventoy -I /dev/sda
```

Confirm both destructive prompts from Ventoy only after rechecking that `/dev/sda` is the intended USB device.

Expected final layout:

```text
/dev/sda1  exfat  Ventoy
/dev/sda2  vfat   VTOYEFI
```

## Download the NixOS Minimal ISO

Create a temporary workspace and download the ISO plus checksum:

```sh
mkdir -p /tmp/nixos-ventoy

curl -L \
  -o /tmp/nixos-ventoy/latest-nixos-minimal-x86_64-linux.iso.sha256 \
  https://channels.nixos.org/nixos-25.11/latest-nixos-minimal-x86_64-linux.iso.sha256

curl -L \
  -o /tmp/nixos-ventoy/latest-nixos-minimal-x86_64-linux.iso \
  https://channels.nixos.org/nixos-25.11/latest-nixos-minimal-x86_64-linux.iso
```

Verify the checksum:

```sh
sha256sum /tmp/nixos-ventoy/latest-nixos-minimal-x86_64-linux.iso
cat /tmp/nixos-ventoy/latest-nixos-minimal-x86_64-linux.iso.sha256
```

The recorded ISO was:

```text
nixos-minimal-25.11.11278.b77b3de87756-x86_64-linux.iso
sha256: b7ab965ab5c7130aaab82ac9ecf685c97c3e7f681aff2e2aa3022f7a8cfd63ee
```

## Copy the ISO to Ventoy

Mount the Ventoy data partition, copy the ISO, flush writes, and unmount:

```sh
sudo mkdir -p /mnt/ventoy
sudo mount /dev/sda1 /mnt/ventoy
sudo cp /tmp/nixos-ventoy/latest-nixos-minimal-x86_64-linux.iso /mnt/ventoy/
sync
sudo umount /mnt/ventoy
```

`sync` can take several minutes on slow USB sticks. Do not unplug the drive while `sync` or `umount` is still running.

## Final Check

After unmounting, verify that the Ventoy partitions remain visible and have no active mountpoint:

```sh
lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,MOUNTPOINTS /dev/sda
```

Expected result:

```text
sda
+-sda1  exfat  Ventoy
+-sda2  vfat   VTOYEFI
```

At this point the USB drive can be unplugged and used to boot the NixOS Minimal installer from the Ventoy menu.
