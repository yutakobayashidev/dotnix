{ username, pkgs, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/terminal.nix
      ../../../modules/profiles/home/development.nix
      ../../../modules/home/gallery-dl
      ../../../applications/whipper
      ../../../applications/beets
      ./ghtkn-agent.nix
    ];
    home.packages = [ pkgs.discrawl ];
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
      jobs.fanbox-supporting = {
        urls = [ "https://fanbox.cc/home/supporting" ];
        startAt = "daily";
      };
    };
    systemd.user.services.oci-retry = {
      Unit = {
        Description = "OCI nix-builder retry loop";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "%h/ghq/github.com/yutakobayashidev/dotnix/infra/oci/nix-builder/oci-retry.sh";
        Restart = "on-failure";
        RestartSec = "60s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    home.homeDirectory = "/home/${username}";
  };

  users.users.${username}.extraGroups = [ "cdrom" ];
}
