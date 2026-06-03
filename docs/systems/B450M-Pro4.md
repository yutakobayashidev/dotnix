# B450M-Pro4 (NixOS) Installation Guide

## First Installation

B450M-Pro4 uses LUKS encryption with Btrfs and impermanence. These steps are for a fresh install.

### Prerequisites

- B450M-Pro4 connected to the LAN (Ethernet)
- pixiecore netboot service running (see `systems/nixos/services/netboot/`)
- Strong LUKS passphrase

### 1. PXE Boot

Turn on the B450M-Pro4 and select PXE / Network Boot from the BIOS boot menu.
The machine will boot into the NixOS installer with:

- NetworkManager auto-started (DHCP)
- SSH enabled (root password: `netboot`)
- Root auto-login on console

### 2. Confirm Target Disk

```sh
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/ | grep -E 'nvme|ata'
```

### 3. Place SOPS Age Key

`nixos-anywhere` 実行中に sops-nix が secrets を復号するため、事前に B450M 用の age 秘密鍵をターゲットに配置する必要がある。配置しないと `generateKey = true` によりランダムな鍵が生成され、`.sops.yaml` の recipient と一致せず復号に失敗する。

```sh
# Mac 側（age 鍵を生成したマシン）で実行
scp ~/.config/sops/age/b450m-pro4.keys.txt root@<TARGET_IP>:~/.config/sops/age/keys.txt
```

ターゲット側でパーミッションを確認:

```sh
ssh root@<TARGET_IP> -- 'mkdir -p ~/.config/sops/age && chmod 600 ~/.config/sops/age/keys.txt'
```

> **Note**: `sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]` は SSH ホスト鍵から age 鍵を派生させるフォールバックだが、この SSH 鍵の age 公開鍵は `.sops.yaml` に recipient 登録されていないため復号には使えない。`nix-anywhere` 時に SSH ホスト鍵が生成されても secrets 復号の役には立たない。

### 4. Run nixos-anywhere

Run this from another machine.

WARNING: This erases all data on the target disk. The current disko config targets `/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_250GB_S4EUNG0M204721K`.

```sh
read -s -p "Enter LUKS passphrase: " LUKS_PASS

nix run github:nix-community/nixos-anywhere -- \
  --flake github:yutakobayashidev/dotnix#B450M-Pro4 \
  --disk-encryption-keys /tmp/luks-password <(printf '%s' "$LUKS_PASS") \
  root@<TARGET_IP>

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
