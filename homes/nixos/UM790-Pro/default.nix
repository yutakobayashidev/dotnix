{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../desktop.nix
      ../../../applications/course-cli
      ../desktop.nix
    ];
    home.homeDirectory = "/home/${username}";
    services.wallpaper.imagePath = "/home/${username}/wallpapers/wp13990714.png";
  };
}
