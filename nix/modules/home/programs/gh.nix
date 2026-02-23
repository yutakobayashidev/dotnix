{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-graph
      pkgs.gh-nippou
      pkgs.gh-dash
      pkgs.gh-actions-cache
      pkgs.gh-poi
      pkgs.gh-notify
      pkgs.gh-do
    ];
  };

  home.packages = with pkgs; [
    ghq
    tea
  ];
}
