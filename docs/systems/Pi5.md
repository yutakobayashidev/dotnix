# Pi 5 (NixOS) Installation Guide

## Initial Setup

1. Flash a 64-bit NixOS image or installer media for `aarch64-linux`.

2. Partition the SD card with two labels:
   - `boot` as `vfat`
   - `nixos` as `ext4`

3. Clone this repository:

   ```sh
   mkdir -p ~/ghq/github.com/yutakobayashidev
   nix shell nixpkgs#git -c git clone https://github.com/yutakobayashidev/dotnix.git ~/ghq/github.com/yutakobayashidev/dotnix
   cd ~/ghq/github.com/yutakobayashidev/dotnix
   ```

4. Apply the Pi 5 configuration:

   ```sh
   sudo nixos-rebuild switch --flake .#pi5
   ```

## Notes

- The host is configured for Ethernet + DHCP and SSH only.
- The machine name is `pi5`.
- The configuration expects the root filesystem from `/dev/disk/by-label/nixos` and the boot partition from `/dev/disk/by-label/boot`.
