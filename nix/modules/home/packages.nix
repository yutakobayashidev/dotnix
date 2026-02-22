# home-managerの共通パッケージリスト（Linux/macOS共通）
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Overlay packages
    claude-code
    ccusage
    codex
    opencode
    vibe-kanban
    aqua

    # Version Control
    git
    git-wt
    lazygit
    jujutsu
    jj-desc
    entire

    # Development Tools
    moonbit-bin.moonbit.latest
    nil
    nixfmt-tree
    nix-init
    google-cloud-sdk
    nodejs_22
    bun
    ni

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
    similarity-ts
    lsd
    btop
    zoxide
    tree
    glow
    vhs
    zellij
    yazi
    keifu

    # Network Tools
    speedtest-cli
    bandwhich
    nmap
    dnsutils

    # Misc
    sl
    fastfetch
  ];
}
