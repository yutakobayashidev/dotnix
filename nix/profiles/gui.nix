{ niri, ... }:
{
  imports = [
    ./cli.nix
    ./../modules/core/niri.nix
    ./../modules/core/input.nix
    ./../modules/core/yubikey.nix
    ./../modules/core/audio.nix
    ./../modules/core/bluetooth.nix
    ./../modules/core/android.nix
  ];

  # Enable CUPS to print documents
  services.printing.enable = true;

  home-manager.users.yuta.imports = [
    niri.homeModules.niri
    ./../modules/home/niri.nix
    ./../modules/home/programs/vscode.nix
    ./../modules/home/programs/waybar.nix
    ./../modules/home/programs/ghostty
    ./../modules/home/programs/swayidle.nix
    ./../modules/home/programs/swaylock.nix
  ];
}
