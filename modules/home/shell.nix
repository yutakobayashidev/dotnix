{ config, pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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
}
