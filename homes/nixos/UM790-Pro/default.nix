{ username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../modules/profiles/home/development.nix
      ../../../modules/profiles/home/desktop/ai.nix
      ../../../modules/profiles/home/desktop/android.nix
      ../../../modules/profiles/home/desktop/communication.nix
      ../../../modules/profiles/home/desktop/media.nix
      ../../../modules/profiles/home/desktop/productivity.nix
      ../../../modules/profiles/home/desktop/security.nix
      ../../../modules/profiles/home/network.nix
      ../../desktop.nix
      ../desktop.nix
    ];
    home.homeDirectory = "/home/${username}";
  };
}
