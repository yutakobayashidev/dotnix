{ lib, pkgs, ... }:

{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      pam_u2f
      pamtester
      yubikey-manager
      yubioath-flutter
    ];
}
