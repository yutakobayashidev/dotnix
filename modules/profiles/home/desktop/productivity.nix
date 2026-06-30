{ lib, pkgs, ... }:

{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      libreoffice
      nextcloud-client
      stable.anki
    ];
}
