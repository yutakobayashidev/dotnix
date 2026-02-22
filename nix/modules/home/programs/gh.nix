{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-graph
      pkgs.gh-nippou
    ];
  };

  home.packages = with pkgs; [
    ghq
    tea
  ];
}
