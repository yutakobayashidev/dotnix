{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../desktop.nix
      ../desktop.nix
      ./twitter-lite.nix
      ./beeper.nix
    ];
    my.programs.course-cli.enable = true;
    home.homeDirectory = "/home/${username}";
    services.wallpaper.imagePath = "/home/${username}/wallpapers/wp13990714.png";
  };
}
