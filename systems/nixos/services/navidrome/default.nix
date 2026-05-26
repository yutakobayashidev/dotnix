{ ... }:
{
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/var/lib/nextcloud/data/yuta/files/music";
      EnableSharing = true;
    };
  };

  users.users.navidrome.extraGroups = [ "nextcloud" ];
}
