# Primitive CLI tools installed on every Home Manager host.
{ lib, pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      aria2
      coreutils
      curl
      curl-impersonate
      eza
      fzf
      glow
      gum
      jq
      jnv
      jolt-tui
      magika
      pueue
      qrcode
      ripgrep
      roots
      sshpass
      tokei
      unar
      wget
      xh
      yazi
      zoxide
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      arp-scan
      binutils
      brightnessctl
      kubo
      nautilus
      psmisc
      rpi-imager
    ];

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
}
