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
    ./modules/home/bat.nix
  ];

  home.username = "yuta";
  home.homeDirectory = "/home/yuta";

  home.packages = with pkgs; [
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
  wayland.windowManager.hyprland.settings = import ./modules/home/hyprland.nix { inherit pkgs; };
  wayland.windowManager.hyprland.extraConfig = ''
    windowrule {
      name = spotify-to-scratchpad
      match:class = Spotify
      workspace = special:magic silent
    }
  '';

  home.stateVersion = "25.11";
}
