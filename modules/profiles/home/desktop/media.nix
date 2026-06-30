{ lib, pkgs, ... }:

let
  immich-go = pkgs.symlinkJoin {
    name = "immich-go-no-docs";
    paths = [ pkgs.immich-go ];
    postBuild = ''
      rm -f $out/bin/docs
    '';
  };
in
{
  home.packages =
    with pkgs;
    [
      apkeep
      exiftool
      ffmpeg
      imagemagick
      immich-go
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
