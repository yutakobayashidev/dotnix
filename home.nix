{ config, pkgs, ... }:

{
  
  imports = [
    ./modules/home/vscode.nix
    ./modules/home/hyprpanel.nix
    ./modules/home/ghostty
    ./modules/home/git.nix
    ./modules/home/neovim.nix
    ./modules/home/zsh.nix
    ./modules/home/tmux.nix
  ];

  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.packages = with pkgs; [
   git
   curl
   wget
   vscode
   nil
   claude-code
   _1password-gui
   rofi
   cliphist
   wl-clipboard
   swww
   spotify
   discord
   slack
   obsidian
   fastfetch
   gh
   google-cloud-sdk
   glow
   ripgrep
   lsd
   bat
   btop
   zoxide
   sl
   fzf
   ghq
   tokei
   jnv
   vhs
   xh
   aria2
   jq
   speedtest-cli
   bandwhich
   peco
   tree
   tea
  ];

  home.stateVersion = "25.11";
}
