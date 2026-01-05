{ config, pkgs, ... }:

{
  
  imports = [
    ./vscode.nix
  ];

  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.packages = with pkgs; [
   git
   curl
   wget
   vim
   vscode
   nil
   _1password-gui
  ];

  programs.git = {
    enable = true;
    userName = "yutakobayashidev";
    userEmail = "hi@yutakobayashi.com";
  };

  home.stateVersion = "25.11";
}
