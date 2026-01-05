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
   google-cloud-sdk
   glow
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "yutakobayashidev";
      email = "hi@yutakobayashi.com";
    };
    extraConfig = {
      credential."https://github.com".helper = "!gh auth git-credential";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      g = "git";
    };
    initExtra = ''
      eval "$(direnv hook bash)"
    '';
  };

  home.stateVersion = "25.11";
}
