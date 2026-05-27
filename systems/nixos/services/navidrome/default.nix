{ ... }:
{
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/srv/bulk/music";
      EnableSharing = true;
    };
  };
}
