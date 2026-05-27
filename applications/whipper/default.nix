{ pkgs, ... }:
{
  home.packages = [ pkgs.whipper ];

  xdg.configFile."whipper/whipper.conf".text = ''
    [whipper.cd.rip]
    output_directory = /srv/bulk/music/_inbox
    unknown = True
    cdr = True
    cover_art = complete

    [musicbrainz]
    https = True
  '';
}
