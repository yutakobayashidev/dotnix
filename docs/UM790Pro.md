# UM790 Pro (NixOS) Installation Guide

## Initial Setup

1. Install NixOS with the unstable channel

2. Clone this repository:

   ```sh
   git clone https://github.com/yutakobayashidev/dotnix.git ~/ghq/github.com/yutakobayashidev/dotnix
   cd ~/ghq/github.com/yutakobayashidev/dotnix
   ```

3. Apply the NixOS configuration:

   ```sh
   sudo nixos-rebuild switch --flake .#UM790-Pro
   ```

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
