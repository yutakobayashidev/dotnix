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
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -la";
      lt = "lsd --tree";
      cat = "bat";
    };
    initContent = ''
      eval "$(direnv hook zsh)"
      eval "$(zoxide init zsh)"
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
