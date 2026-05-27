{ pkgs, lib, ... }:
let
  whipperConf = {
    "whipper.cd.rip" = {
      output_directory = "/srv/bulk/music/_inbox";
      unknown = true;
      cdr = true;
      cover_art = "complete";
    };
    musicbrainz.https = true;
  };
in
{
  home.packages = [ pkgs.whipper ];

  xdg.configFile."whipper/whipper.conf".text =
    lib.generators.toINI { } whipperConf;
}
