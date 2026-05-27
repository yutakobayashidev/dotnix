{ pkgs, config, lib, ... }:
let
  whipperConfigDir = "${config.xdg.configHome}/whipper";
  whipperConfAttrs = {
    "whipper.cd.rip" = {
      output_directory = "/srv/bulk/music/_inbox";
      unknown = true;
      cdr = true;
      cover_art = "complete";
    };
    musicbrainz.https = true;
  };
  whipperConf = pkgs.writeText "whipper.conf"
    (lib.generators.toINI { } whipperConfAttrs);
in
{
  home.packages = [ pkgs.whipper ];

  home.activation.writeWhipperConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${whipperConfigDir}/whipper.conf" ]; then
      mkdir -p "${whipperConfigDir}"
      ${pkgs.coreutils}/bin/install -m 644 ${whipperConf} "${whipperConfigDir}/whipper.conf"
    fi
  '';
}
