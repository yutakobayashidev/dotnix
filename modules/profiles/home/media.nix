{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  bird = inputs.bird.packages.${pkgs.stdenv.hostPlatform.system}.bird;
  edcb-tools = inputs.edcb-tools.packages.${pkgs.stdenv.hostPlatform.system}.edcb-tools;
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
      bird
      defuddle
      discrawl
      edcb-tools
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
