{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/terminal.nix
    ];
    home.homeDirectory = "/home/${username}";
  };
}
