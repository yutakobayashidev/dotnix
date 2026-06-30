{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    home.homeDirectory = "/home/${username}";
  };
}
