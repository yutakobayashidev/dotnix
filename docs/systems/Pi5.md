# Pi 5 (NixOS) Installation Guide

## Prerequisites

- Pi 5 with SD card or USB boot media
- Network connectivity (Ethernet recommended)

## Initial Setup

### 1. Flash Media

Flash a 64-bit NixOS installer image for `aarch64-linux` to an SD card or USB drive.

### 2. PXE Boot (Alternative)

If an aarch64 netboot image is configured on the netboot server (see `systems/nixos/services/netboot/`), the Pi 5 can PXE boot via the `config.txt` option `program_usb_boot_mode=1`. By default only `x86_64-linux` netboot images are served.

### 3. Partition

Partition the SD card with two labels:

- `boot` as `vfat`
- `nixos` as `ext4`

### 4. Clone and Install

```sh
mkdir -p ~/ghq/github.com/yutakobayashidev
nix shell nixpkgs#git -c git clone https://github.com/yutakobayashidev/dotnix.git ~/ghq/github.com/yutakobayashidev/dotnix
cd ~/ghq/github.com/yutakobayashidev/dotnix
sudo nixos-rebuild switch --flake .#pi5
```

## Notes

- The host is configured for Ethernet + DHCP and SSH only.
- The machine name is `pi5`.
- The configuration expects the root filesystem from `/dev/disk/by-label/nixos` and the boot partition from `/dev/disk/by-label/boot`.
