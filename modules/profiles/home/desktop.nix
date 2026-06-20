{ lib, pkgs, ... }:

{
  imports = [
    ../../../applications/vrchat
    ../../../applications/chromium
    ../../../applications/firefox
    ../../../applications/keifu
    ../../../applications/obs-studio
    ../../../applications/ghostty
    ../../../applications/zaproxy
    ../../../applications/zed-editor
  ];

  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      # AI / LLM
      lmstudio

      # Overlay packages
      ghostty

      # Android
      android-tools
      android-studio

      # YubiKey
      yubikey-manager
      yubioath-flutter
      pam_u2f
      pamtester

      # Browsers & communication
      google-chrome
      discord
      signal-desktop
      slack

      # Productivity
      stable.anki
      insomnia
      libreoffice
      nextcloud-client

      # Media
      kooha
      spotify

      # Wayland tools
      rofi
      cliphist
      wl-clipboard
      swww
      grimblast
      swappy
      zenity

      # Screen management
      brightnessctl

      # System tools
      kubo
      rpi-imager
      difit
      binutils
      arp-scan

      # Misc
      cava
      nautilus
    ];
}
