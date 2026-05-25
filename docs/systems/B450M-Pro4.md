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

If the target machine cannot reach the internet directly, share the UM790-Pro
connection over a direct LAN cable:

1. On the UM790-Pro, find the wired interface name:

   ```sh
   nmcli device
   ```

2. Create a shared connection on that wired interface. Replace `enp1s0` with
   the actual wired interface name:

   ```sh
   sudo nmcli con add type ethernet ifname enp1s0 con-name shared-b450 ipv4.method shared ipv6.method ignore
   sudo nmcli con up shared-b450
   ```

3. If the B450M-Pro4 side sends DHCP requests but never receives a `10.42.0.x`
   address, check whether the requests reach UM790-Pro:

   ```sh
   nix shell nixpkgs#tcpdump -c sudo tcpdump -ni enp1s0 'port 67 or port 68'
   ```

   If `DHCP Request` or `DHCP Discover` packets appear but no lease is
   assigned, allow DHCP and DNS through the UM790-Pro NixOS firewall:

   ```sh
   sudo iptables -I nixos-fw 1 -i enp1s0 -p udp --dport 67 -j nixos-fw-accept
   sudo iptables -I nixos-fw 2 -i enp1s0 -p udp --dport 53 -j nixos-fw-accept
   sudo iptables -I nixos-fw 3 -i enp1s0 -p tcp --dport 53 -j nixos-fw-accept
   ```

4. If the B450M-Pro4 side receives a `10.42.0.x` address but cannot reach the
   internet, add temporary NAT and forwarding rules on UM790-Pro. Replace
   `wlp2s0` with the UM790-Pro Wi-Fi interface if different:

   ```sh
   sudo iptables -t nat -A POSTROUTING -s 10.42.0.0/24 -o wlp2s0 -j MASQUERADE
   sudo iptables -I FORWARD 1 -i enp1s0 -o wlp2s0 -j ACCEPT
   sudo iptables -I FORWARD 1 -i wlp2s0 -o enp1s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
   ```

5. On the B450M-Pro4 installer, reconnect Ethernet and confirm internet access.
   Replace `enp5s0` with the B450M-Pro4 wired interface if different:

   ```sh
   sudo systemctl start NetworkManager
   sudo nmcli device disconnect enp5s0
   sudo nmcli device connect enp5s0
   ip -4 addr show enp5s0
   ping -c 3 github.com
   ```

6. Use that address from the UM790-Pro:

   ```sh
   ssh nixos@10.42.0.x
   ```

7. When you are done, remove the shared connection on the UM790-Pro:

   ```sh
   sudo nmcli con down shared-b450
   sudo nmcli con delete shared-b450
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

### 4. Place SOPS Age Key

`nixos-anywhere` 実行中に sops-nix が secrets を復号するため、事前に B450M 用の age 秘密鍵をターゲットに配置する必要がある。配置しないと `generateKey = true` によりランダムな鍵が生成され、`.sops.yaml` の recipient と一致せず復号に失敗する。

```sh
# Mac 側（age 鍵を生成したマシン）で実行
scp ~/.config/sops/age/b450m-pro4.keys.txt nixos@<TARGET_IP>:~/.config/sops/age/keys.txt
```

ターゲット側でパーミッションを確認:

```sh
ssh nixos@<TARGET_IP> -- 'mkdir -p ~/.config/sops/age && chmod 600 ~/.config/sops/age/keys.txt'
```

> **Note**: `sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]` は SSH ホスト鍵から age 鍵を派生させるフォールバックだが、この SSH 鍵の age 公開鍵は `.sops.yaml` に recipient 登録されていないため復号には使えない。`nix-anywhere` 時に SSH ホスト鍵が生成されても secrets 復号の役には立たない。

### 5. Run nixos-anywhere

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

### 6. Reboot

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
