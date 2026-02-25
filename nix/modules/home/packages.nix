# home-managerの共通パッケージリスト（Linux/macOS共通）
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Overlay packages
    claude-code
    ccusage
    continues
    opencode
    vibe-kanban
    cursor-agent
    # Version Control
    git
    git-wt
    git-lfs
    git-filter-repo
    lazygit
    jujutsu
    jj-desc
    entire

    # Development Tools
    repiq
    nil
    nix-init
    ni

    # Google Suite
    gogcli

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
    stable.yt-dlp
    halloy
    obsidian

    # Network Tools
    tunnelto
    speedtest-cli
    bandwhich
    nmap
    dnsutils

    # Misc
    sl
    fastfetch
  ];
}
