{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../desktop.nix
      ../desktop.nix
      ./twitter-lite.nix
      ./beeper.nix
      ./orca.nix
    ];
    my.programs.course-cli.enable = true;
    services.codex-limit-auto-reset.enable = true;
    home.homeDirectory = "/home/${username}";
    services.wallpaper.imagePath = "/home/${username}/wallpapers/wp13990714.png";
  };
}
