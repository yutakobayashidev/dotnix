{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gh
    gh-nippou
    ghq
    tea
  ];
}
