{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "media";

  home =
    { lib, pkgs, ... }:

    {
      my.programs = {
        bird.enable = lib.mkDefault true;
        discrawl.enable = lib.mkDefault true;
        edcb-tools.enable = lib.mkDefault true;
        obsidian.enable = lib.mkDefault true;
        webforai.enable = lib.mkDefault true;
      };

      home.packages =
        with pkgs;
        [
          apkeep
          exiftool
          ffmpeg
          imagemagick
          immich-go-no-docs
          ipatool
          luanti
          mat2
          mpv
          pdfpc
          sl
          stable.gallery-dl
          stable.yt-dlp
          xurl
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          bitwig-studio
          cava
          dexed
          kooha
          lsp-plugins
          qpwgraph
          spotify
          surge-xt
          vital
          vlc
          wineWow64Packages.staging
          yabridge
          yabridgectl
        ];
    };
}
