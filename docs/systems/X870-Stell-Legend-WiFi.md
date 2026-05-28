# X870 Stell Legend WiFi (NixOS-WSL) Installation Guide

## Prerequisites

- Use the Microsoft Store version of WSL on Windows 10 or 11.
- Prefer WSL 2.4.4 or later so `.wsl` files can be installed directly.

## Install NixOS-WSL

1. Enable WSL from PowerShell:

   ```powershell
   wsl --install --no-distribution
   ```

2. Download the latest `nixos.wsl` release from `nix-community/NixOS-WSL`.

3. Install the downloaded image.

   For WSL 2.4.4 or later, either double-click the `.wsl` file or run:

   ```powershell
   wsl --install --from-file .\nixos.wsl
   ```

   For older WSL versions, import it manually:

   ```powershell
   wsl --import NixOS $env:USERPROFILE\NixOS .\nixos.wsl --version 2
   ```

4. Start the distro:

   ```powershell
   wsl -d NixOS
   ```

## Post-Install

1. Set a password for the default user:

   ```sh
   passwd
   ```

2. Update channels once so `nixos-rebuild` works normally:

   ```sh
   sudo nix-channel --update
   ```

3. Optionally make NixOS the default WSL distro:

   ```powershell
   wsl -s NixOS
   ```

## Apply This Repository

1. Clone this repository inside the NixOS-WSL environment:

   ```sh
   mkdir -p ~/ghq/github.com/yutakobayashidev
   nix shell nixpkgs#git -c git clone https://github.com/yutakobayashidev/dotnix.git ~/ghq/github.com/yutakobayashidev/dotnix
   cd ~/ghq/github.com/yutakobayashidev/dotnix
   ```

2. Apply the host configuration:

   ```sh
   sudo nixos-rebuild switch --flake .#X870-Stell-Legend-WiFi
   ```

3. This host config also installs `xdg-open` and registers a local `file-protocol-handler.desktop` entry so WSL can forward browser opens to the Windows default browser.

   ```sh
   xdg-open https://example.com
   ```

   This also lets commands such as `gh auth login` open `https://github.com/login/device` in the Windows browser.

4. If you want `nix run .#build` and `nix run .#switch` to work on this machine, make sure the runtime hostname is `X870-Stell-Legend-WiFi`.
