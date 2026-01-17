{ ... }:
{
  imports = [
    ./cli.nix
    ./../modules/core/hyprland.nix
    ./../modules/core/input.nix
    ./../modules/core/yubikey.nix
    ./../modules/core/audio.nix
    ./../modules/core/bluetooth.nix
  ];

  # Enable CUPS to print documents
  services.printing.enable = true;

  home-manager.users.yuta.imports = [
    ./../modules/home/hyprland.nix
    ./../modules/home/programs/vscode.nix
    ./../modules/home/programs/hyprpanel.nix
    ./../modules/home/programs/ghostty
    ./../modules/home/programs/hypridle.nix
    ./../modules/home/programs/hyprlock.nix
  ];
}
