# home-managerの共通パッケージリスト（Linux/macOS共通）
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Version Control
    bit-vcs
    git
    git-wt
    git-lfs
    git-filter-repo
    lazygit
    jujutsu
    jj-desc

    # Development Tools
    nil
    nix-init
    ni
    wabt

    # CLI Utilities
    curl
    wget
    aria2
    xh
    ripgrep
    fzf
    peco
    jq
    jnv
    tokei
    cloc
    similarity-ts
    lsd
    btop
    zoxide
    tree
    glow
    gum
    vhs
    yazi
    imagemagick
    ffmpeg
    python313Packages.markitdown
    stable.yt-dlp
    halloy
    obsidian

    # Network Tools
    tunnelto
    speedtest-cli
    bandwhich
    nmap
    dnsutils

    # Presentation
    pdfpc

    # Misc
    sl
    fastfetch
  ];
}
