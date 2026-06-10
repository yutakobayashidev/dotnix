# home-managerの共通パッケージリスト（Linux/macOS共通）
{ pkgs, lib, ... }:

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
      # Version Control
      bit-vcs
      jujutsu
      jj-desc

      # Development Tools
      bumblebee
      gogcli
      nil
      nix-init
      ni
      repiq
      ruff
      taplo
      wabt

      # CLI Utilities
      pueue
      curl-impersonate
      aria2
      jnv
      jolt-tui
      magika
      tokei
      cloc
      similarity-ts
      btop
      roots
      vhs
      yazi
      imagemagick
      exiftool
      mat2
      ffmpeg
      apkeep
      ipatool
      stable.yt-dlp
      stable.gallery-dl
      halloy
      immich-go
      luanti
      nostui
      obsidian
      unar

      # Network Tools
      tunnelto
      speedtest-cli
      bandwhich
      nmap
      dnsutils
      wireguard-tools
      gping

      # Presentation
      pdfpc

      # Misc
      psmisc
      sl
      fastfetch
      ooniprobe-cli
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      python313Packages.markitdown
      proton-vpn-cli
    ];

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
}
