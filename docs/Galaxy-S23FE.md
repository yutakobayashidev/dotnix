# Galaxy S23 FE (nix-on-droid) Installation Guide

Galaxy S23 FE is an Android device running nix-on-droid for a Nix-based environment on mobile.

## Prerequisites

- Galaxy S23 FE (or compatible Android device)
- F-Droid or direct APK installation capability
- Network connectivity (WiFi recommended)

## Step 1: Install nix-on-droid App

Download and install nix-on-droid from F-Droid or GitHub releases:

- F-Droid: https://f-droid.org/packages/com.termux.nix/
- GitHub: https://github.com/nix-community/nix-on-droid/releases

## Step 2: Initial Setup

Open the nix-on-droid app and wait for the initial Nix installation to complete.

## Step 3: Enable Flakes

```sh
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

## Step 4: Clone Configuration

```sh
nix-shell -p git
git clone https://github.com/yutakobayashidev/dotnix.git
cd dotnix
```

## Step 5: Apply Configuration

```sh
nix-on-droid switch --flake .#Galaxy-S23FE --show-trace
```

## Update Configuration

After installation, use this command to apply configuration changes:

```sh
nix-on-droid switch --flake .#Galaxy-S23FE --show-trace
```
