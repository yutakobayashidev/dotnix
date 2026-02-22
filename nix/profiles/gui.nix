{ niri, ... }:
{
  imports = [
    ./cli.nix
    ./../modules/linux/niri.nix
    ./../modules/linux/input.nix
    ./../modules/linux/pam.nix
    ./../modules/linux/audio.nix
    ./../modules/linux/bluetooth.nix
    ./../modules/linux/android.nix
  ];

  services.printing.enable = true;

  home-manager.users.yuta.imports = [
    niri.homeModules.niri
    ./../modules/linux/programs/niri.nix
    ./../modules/linux/programs/waybar.nix
    ./../modules/home/programs/ghostty
    ./../modules/linux/programs/swayidle.nix
    ./../modules/linux/programs/swaylock.nix
  ];
}
