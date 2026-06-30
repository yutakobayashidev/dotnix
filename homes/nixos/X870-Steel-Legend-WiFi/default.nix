{ pkgs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/communication.nix
      ../../../modules/profiles/home/gaming.nix
      ../../../modules/profiles/home/media.nix
      ../../../modules/profiles/home/productivity.nix
      ../../../modules/profiles/home/security.nix
      ../../../modules/profiles/home/network.nix
      ../../desktop.nix
      ../desktop.nix
    ];
    home.packages = [ pkgs.lmstudio ];
    home.homeDirectory = "/home/${username}";
  };
}
