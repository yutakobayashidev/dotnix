{ pkgs, ... }:

{
  imports = [
    ../../../../applications/git
    ../../../../applications/tmux
  ];

  home.packages = [
    pkgs.sshpass
  ];
}
