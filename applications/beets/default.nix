{ pkgs, config, ... }:
let
  beetsWithPlugins = pkgs.beets.overridePythonAttrs (old: {
    dependencies = old.dependencies ++ [ pkgs.beets-copyartifacts ];
  });
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
    plugins = "fetchart embedart scrub replaygain copyartifacts";
    replaygain = {
      backend = "ffmpeg";
      auto = true;
    };
    copyartifacts = {
      extensions = ".cue .log .m3u .jpg .png";
    };
  };
in
{
  home.packages = [ beetsWithPlugins ];

  xdg.configFile."beets/config.yaml".source =
    format.generate "beets-config.yaml" beetsConf;
}
