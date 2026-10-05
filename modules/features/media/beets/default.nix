_:

{
  flake.modules.homeManager.beets =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      format = pkgs.formats.yaml { };
      beetsConf = {
        directory = "/srv/bulk/music";
        library = "/home/yuta/.local/share/beets/library.db";
        import = {
          copy = false;
          move = true;
          write = true;
          resume = "ask";
          incremental = true;
          quiet_fallback = "skip";
          timid = false;
          log = null;
        };
        paths = {
          default = "\${albumartist}/\${album}/\${track} \${title}";
          singleton = "Non-Album/\${artist}/\${title}";
          comp = "Compilations/\${album}/\${track} \${title}";
        };
        ui.color = true;
        plugins = "musicbrainz fetchart embedart scrub replaygain";
        replaygain = {
          backend = "ffmpeg";
          auto = true;
        };
      };
    in
    {
      options.my.programs.beets.enable = lib.mkEnableOption "beets";

      config = lib.mkIf config.my.programs.beets.enable {
        home.packages = with pkgs; [ beets ];

        xdg.configFile."beets/config.yaml".source = format.generate "beets-config.yaml" beetsConf;
      };
    };
}
