{ ... }:

{
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
  ];

  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.stateVersion = "25.11";
}
