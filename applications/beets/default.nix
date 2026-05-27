{ pkgs, ... }:
{
  home.packages = with pkgs; [ beets ];

  xdg.configFile."beets/config.yaml".text = ''
    directory: /srv/bulk/music
    library: /home/yuta/.local/share/beets/library.db
    import:
      copy: no
      move: yes
      write: yes
      resume: ask
      incremental: yes
      quiet_fallback: skip
      timid: no
      log:
    paths:
      default: ''${albumartist}/''${album}/''${track} ''${title}
      singleton: Non-Album/''${artist}/''${title}
      comp: Compilations/''${album}/''${track} ''${title}
    ui:
      color: yes
    plugins: fetchart embedart scrub replaygain
    replaygain:
      backend: ffmpeg
      auto: yes
  '';
}
