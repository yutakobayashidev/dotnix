# Keifu - 系譜図作成ツール
{ pkgs, lib, ... }:

{
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.keifu
  ];
}
