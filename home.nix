{ config, pkgs, ... }:

{
  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.packages = with pkgs; [
   git
   curl
   wget
   vim 
  ];

  programs.git = {
    enable = true;
    userName = "yutakobayashidev";
    userEmail = "hi@yutakobayashi.com";
  };

  home.stateVersion = "25.11";
}
