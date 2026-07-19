{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/development.nix
      ../../../modules/profiles/home/communication.nix
      ../../../modules/profiles/home/media.nix
      ../../../modules/profiles/home/productivity.nix
      ../../../modules/profiles/home/security.nix
      ../../../modules/profiles/home/network.nix
      ../../desktop.nix
      ../../../applications/course-cli
      ../desktop.nix
    ];
    home.homeDirectory = "/home/${username}";
    services.wallpaper.imagePath = "/home/${username}/wallpapers/wp13990714.png";
  };
}
