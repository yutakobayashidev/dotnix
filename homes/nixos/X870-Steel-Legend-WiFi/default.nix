{ pkgs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../desktop.nix
      ../desktop.nix
    ];
    home.packages = with pkgs; [
      davinci-resolve
      lmstudio
    ];
    home.homeDirectory = "/home/${username}";
  };
}
