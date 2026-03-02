# 外部flake input由来の開発ツール
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gogcli
    repiq
  ];
}
