{ config, pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      g = "git";
      rebuild = "sudo nixos-rebuild switch --flake /home/yuta/nixos#nixos";
    };
    initExtra = ''
      eval "$(direnv hook zsh)"
    '';
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "docker"
        "kubectl"
        "history"
        "sudo"
      ];
    };
  };
}
