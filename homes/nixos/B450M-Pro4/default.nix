{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../nix/modules/profiles/home/terminal.nix
      ../../../nix/modules/profiles/home/development.nix
      ../../../applications/abcde
    ];
    home.homeDirectory = "/home/${username}";
  };
}
