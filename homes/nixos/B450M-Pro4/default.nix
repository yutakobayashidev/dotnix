{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../nix/modules/profiles/home/terminal.nix
      ../../../nix/modules/profiles/home/development.nix
    ];
    home.homeDirectory = "/home/${username}";
  };
}
