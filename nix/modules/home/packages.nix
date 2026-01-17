# home-managerのパッケージリスト
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Overlay packages
    ghostty
    claude-code
    ccusage
    codex
    opencode
    aqua

    # Version Control
    git
    jujutsu

    # Development Tools
    nil
    nixfmt-tree
    google-cloud-sdk
    bun

    # YubiKey
    yubikey-manager
    yubioath-flutter
    pam_u2f
    pamtester

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
    lsd
    btop
    zoxide
    tree
    glow
    vhs
    zellij

    # Network Tools
    speedtest-cli
    bandwhich
    arp-scan
    nmap
    dnsutils

    # Browsers & Communication
    google-chrome
    discord
    slack

    # Productivity
    vscode
    obsidian
    anki
    _1password-gui

    # Media
    spotify

    # Wayland Tools
    rofi
    cliphist
    wl-clipboard
    swww
    grimblast
    swappy
    zenity

    # Screen Management
    hyprlock
    brightnessctl

    # System Tools
    rpi-imager
    difit

    # Misc
    sl
    cava
    fastfetch
  ];
}
