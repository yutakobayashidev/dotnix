{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/cli.nix
      ../../../modules/profiles/home/desktop.nix
      ../../../applications/niri
      ../../../applications/waybar
      ../../../applications/swayidle
      ../../../applications/swaylock
      ../../../applications/zaproxy
    ];
    home.homeDirectory = "/home/${username}";
  };
}
