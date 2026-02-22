{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gh
    gh-graph
    gh-nippou
    ghq
    tea
  ];
}
