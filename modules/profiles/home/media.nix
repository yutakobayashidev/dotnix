{ lib, pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      apkeep
      bird
      defuddle
      discrawl
      edcb-tools
      exiftool
      ffmpeg
      imagemagick
      immich-go-no-docs
      ipatool
      luanti
      mat2
      mpv
      obsidian
      pdfpc
      sl
      stable.gallery-dl
      stable.yt-dlp
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      cava
      kooha
      spotify
    ];
}
