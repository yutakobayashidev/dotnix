# Linux固有パッケージ
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Overlay packages (Linux-only)
    ghostty

    # Android
    android-tools
    android-studio

    # YubiKey
    yubikey-manager
    yubioath-flutter
    pam_u2f
    pamtester

    # Browsers & Communication (Nix管理)
    google-chrome
    discord
    slack

    # Productivity (Nix管理)
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
    binutils
    arp-scan

    # VR
    vrcx

    # Misc
    cava
  ];
}
