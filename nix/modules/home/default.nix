{ ... }:

{
  imports = [
    ./programs/git.nix
    ./programs/jj.nix
    ./programs/zsh.nix
  ];

  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.stateVersion = "25.11";
}
