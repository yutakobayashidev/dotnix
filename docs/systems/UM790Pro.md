# UM790 Pro (NixOS) Installation Guide

## Prerequisites

- UM790-Pro connected to the LAN (Ethernet)
- pixiecore netboot service running (see `systems/nixos/services/netboot/`)

## Initial Setup

### 1. PXE Boot

Turn on the UM790-Pro and select PXE / Network Boot from the BIOS boot menu.
The machine will boot into the NixOS installer with:

- NetworkManager auto-started (DHCP)
- SSH enabled (root password: `netboot`)
- Root auto-login on console

### 2. Partition Disk

```sh
lsblk
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart primary 512MiB 100%
sudo mkfs.ext4 -L nixos /dev/nvme0n1p1
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1  # if UEFI boot needed
sudo mount /dev/disk/by-label/nixos /mnt
```

### 3. Clone and Install

```sh
nix shell nixpkgs#git -c git clone https://github.com/yutakobayashidev/dotnix.git /mnt/etc/dotnix
sudo nixos-install --flake /mnt/etc/dotnix#UM790-Pro --root /mnt
```

### 4. Reboot

```sh
sudo umount -R /mnt
sudo reboot
```

## Post-Install

After reboot, VirtualBox is enabled on this host. Log out and back in so the `vboxusers` group is applied to your session.

## YubiKey Setup

YubiKeyでpolkit認証（1Passwordのロック解除など）を行うための設定。

### 1. YubiKeyの登録

```bash
mkdir -p ~/.config/Yubico
pamu2fcfg -o pam://UM790-Pro -i pam://UM790-Pro > ~/.config/Yubico/u2f_keys
```

### 2. 動作確認

```bash
pamtester polkit-1 yuta authenticate
```

YubiKeyをタッチして「successfully authenticated」と表示されればOK。

### 3. 1Password設定

1Password → 設定 → セキュリティ → 「システム認証でロック解除」を有効化
