{ config, pkgs, ... }:

{

  imports = [
    ./programs/vscode.nix
    ./programs/hyprpanel.nix
    ./programs/ghostty
    ./programs/git.nix
    ./programs/gh.nix
    ./programs/neovim.nix
    ./programs/zsh.nix
    ./programs/tmux.nix
    ./programs/bat.nix
    ./programs/hypridle.nix
    ./programs/hyprlock.nix
    ./programs/fastfetch
    ./programs/btop.nix
  ];

  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.packages = with pkgs; [
    # Overlay packages
    ghostty
    claude-code
    ccusage
    codex
    opencode
    aqua
    # System
    git
    jujutsu
    curl
    # YubiKey
    yubikey-manager
    yubioath-flutter
    pam_u2f
    pamtester
    wget
    vscode
    nil
    nixfmt-tree
    _1password-gui
    rofi
    cliphist
    wl-clipboard
    swww
    spotify
    discord
    slack
    obsidian
    google-chrome
    anki
    fastfetch
    google-cloud-sdk
    glow
    ripgrep
    lsd
    btop
    zellij
    zoxide
    sl
    fzf
    tokei
    jnv
    vhs
    xh
    aria2
    jq
    speedtest-cli
    bandwhich
    peco
    tree
    cava
    grimblast
    swappy
    zenity
    bun
    difit
    arp-scan
    nmap
    rpi-imager
    dnsutils
    # Screen locking & idle management
    hyprlock
    brightnessctl
  ];

  # Hyprland
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.settings = import ./programs/hyprland.nix { inherit pkgs; };
  wayland.windowManager.hyprland.extraConfig = ''
    windowrule {
      name = spotify-to-scratchpad
      match:class = Spotify
      workspace = special:magic silent
    }
  '';

  home.stateVersion = "25.11";
}
