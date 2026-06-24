# home-managerの共通パッケージリスト（Linux/macOS共通）
{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  bird = inputs.bird.packages.${pkgs.stdenv.hostPlatform.system}.bird;
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
      babashka
      before-and-after
      bird
      bumblebee
      defuddle
      gctx
      vulnix
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
      vhs
      yazi
      imagemagick
      exiftool
      mat2
      ffmpeg
      mpv
      apkeep
      ipatool
      whichllm
      stable.yt-dlp
      stable.gallery-dl
      halloy
      llm-agents.herdr
      llm-agents.hunk
      immich-go
      luanti
      nostui
      obsidian
      unar

      # Network Tools
      cloudflared
      vt-cli
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
      sl
      qrcode
      fastfetch
      ooniprobe-cli
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      psmisc
      python313Packages.markitdown
      proton-vpn-cli
    ];

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
}
