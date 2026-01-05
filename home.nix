{ config, pkgs, ... }:

{
  
  imports = [
    ./modules/home/vscode.nix
    ./modules/home/hyprpanel.nix
    ./modules/home/ghostty
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
   claude-code
   _1password-gui
   rofi
   swww
   spotify
   discord
   slack
   obsidian
   fastfetch
   gh
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "yutakobayashidev";
      email = "hi@yutakobayashi.com";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      g = "git";
    };
  };

  home.stateVersion = "25.11";
}
