{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../nix/modules/profiles/home/terminal.nix
      ../../../nix/modules/profiles/home/development.nix
      ../../../applications/whipper
      ../../../applications/beets
    ];
    home.homeDirectory = "/home/${username}";
  };

  users.users.${username}.extraGroups = [ "cdrom" ];
}
