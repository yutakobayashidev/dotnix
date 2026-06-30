{ lib, pkgs, ... }:

{
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.ghostty
  ];

  home.file.".config/ghostty/config" = {
    source = ./config;
  };
}
