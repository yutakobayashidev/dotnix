_:

{
  flake.modules.homeManager.whipper =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      whipperConfigDir = "${config.xdg.configHome}/whipper";
      whipperConfAttrs = {
        "whipper.cd.rip" = {
          output_directory = "/srv/bulk/music/_inbox";
          unknown = true;
          cdr = true;
        };
        musicbrainz.https = true;
      };
      whipperConf = pkgs.writeText "whipper.conf" (lib.generators.toINI { } whipperConfAttrs);
    in
    {
      options.my.programs.whipper.enable = lib.mkEnableOption "whipper";

      config = lib.mkIf config.my.programs.whipper.enable {
        home.packages = [ pkgs.stable.whipper ];

        home.activation.writeWhipperConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ ! -f "${whipperConfigDir}/whipper.conf" ]; then
            mkdir -p "${whipperConfigDir}"
            ${pkgs.coreutils}/bin/install -m 644 ${whipperConf} "${whipperConfigDir}/whipper.conf"
          fi
        '';
      };
    };
}
