# Primitive CLI tools installed on every Home Manager host.
{ lib, pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      aria2
      coreutils
      curl
      eza
      fzf
      glow
      gum
      jq
      jnv
      jolt-tui
      pueue
      qrcode
      ripgrep
      roots
      tokei
      unar
      unzip
      wget
      xh
      yazi
      zoxide
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      brightnessctl
      kubo
      nautilus
      psmisc
      rpi-imager
      usbutils
    ];

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
}
