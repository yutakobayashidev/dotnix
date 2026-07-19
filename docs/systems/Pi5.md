# Pi 5 (NixOS) Installation Guide

## Prerequisites

- Pi 5 with SD card or USB boot media
- Network connectivity (Ethernet recommended)

## Initial Setup

### 1. Flash Media

Download an official 64-bit `aarch64-linux` image from the [NixOS download page](https://nixos.org/download/#nixos-iso) and flash it to an SD card or USB drive. The custom installer ISO in this repository is x86_64-only and cannot boot the Pi 5.

### 2. Partition

Partition the SD card with two labels:

- `boot` as `vfat`
- `nixos` as `ext4`

### 3. Clone and Install

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
