{ lib, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../nix/modules/profiles/home/terminal.nix
      ../../../nix/modules/profiles/home/development.nix
      ../../../nix/modules/home/gallery-dl
      ../../../applications/whipper
      ../../../applications/beets
    ];
    my.programs.gallery-dl = {
      enable = true;
      archivePath = "/srv/bulk/gallery-dl";
      extraArgs = [ ];
      settings = {
        extractor = {
          base-directory = "/srv/bulk/gallery-dl";
          archive = "/srv/bulk/gallery-dl/archive.sqlite3";
          pixiv = {
            filename = "{id}_p{num}.{extension}";
            directory = [
              "pixiv"
              "bookmarks"
              "{user[id]}_{user[account]}"
            ];
          };
        };
      };
      jobs.pixiv-bookmarks = {
        urls = [ "https://www.pixiv.net/users/{PIXIV_USER_ID}/bookmarks/artworks" ];
        startAt = "daily";
      };
    };
    home.homeDirectory = "/home/${username}";
  };

  users.users.${username}.extraGroups = [ "cdrom" ];
}
