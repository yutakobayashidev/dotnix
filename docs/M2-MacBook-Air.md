# M2 MacBook Air (macOS) Installation Guide

## Initial Setup

1. Install [Nix](https://github.com/NixOS/nix-installer):

   ```sh
   curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
   ```

2. Clone this repository:

   ```sh
   git clone https://github.com/yutakobayashidev/dotnix.git ~/ghq/github.com/yutakobayashidev/dotnix
   cd ~/ghq/github.com/yutakobayashidev/dotnix
   ```

3. Apply the nix-darwin configuration (this will also install Homebrew automatically):

   ```sh
   sudo nix run nix-darwin -- switch --flake .#darwin
   ```

4. Reload your shell:

   ```sh
   exec zsh
   ```
