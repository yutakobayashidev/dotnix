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
    vibe-kanban
    aqua

    # Version Control
    git
    git-wt
    git-wt-clean
    jujutsu
    jj-desc
    entire

    # Development Tools
    nil
    nixfmt-tree
    nix-init
    google-cloud-sdk
    nodejs_22
    bun
    ni
    android-tools
    android-studio

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
    insomnia

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
