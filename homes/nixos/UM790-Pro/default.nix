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
    my.programs.dsh.web = {
      enable = true;
      host = "100.91.91.87";
      publicUrl = "https://dsh.home.yutakobayashi.com/";
      trustedHosts = [ "dsh.home.yutakobayashi.com" ];
    };
    services.codex-limit-auto-reset.enable = true;
    home.homeDirectory = "/home/${username}";
    services.wallpaper.imagePath = "/home/${username}/wallpapers/wp13990714.png";
  };
}
