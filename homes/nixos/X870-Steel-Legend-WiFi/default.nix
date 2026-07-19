{ pkgs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../desktop.nix
      ../desktop.nix
    ];
    home.packages = [ pkgs.lmstudio ];
    home.homeDirectory = "/home/${username}";
  };
}
