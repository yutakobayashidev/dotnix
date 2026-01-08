{ config, pkgs, ... }:

{
  
  imports = [
    ./programs/vscode.nix
    ./programs/hyprpanel.nix
    ./programs/ghostty
    ./programs/git.nix
    ./programs/neovim.nix
    ./programs/zsh.nix
    ./programs/tmux.nix
    ./programs/bat.nix
  ];

  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.packages = with pkgs; [
   # Overlay packages
   ghostty
   claude-code
   ccusage
   codex
   gh-nippou
   # System
   git
   curl
   wget
   vscode
   nil
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
   cava
   grimblast
   swappy
   zenity
   bun
   arp-scan
   nmap
   rpi-imager
   dnsutils
  ];

  # Hyprland
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.settings = import ./programs/hyprland.nix { inherit pkgs; };
  wayland.windowManager.hyprland.extraConfig = ''
    windowrule {
      name = spotify-to-scratchpad
      match:class = Spotify
      workspace = special:magic silent
    }
  '';

  home.stateVersion = "25.11";
}
