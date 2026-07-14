{ inputs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        ../../../modules/profiles/home/development.nix
        ../../../modules/profiles/home/media.nix
        ../../../modules/profiles/home/network.nix
        ../../desktop.nix
        ../../../applications/course-cli
        ../../../applications/nlobby-cli
        ../desktop.nix
        inputs.onepassword-shell-plugins.hmModules.default
      ];
      home.homeDirectory = "/Users/${username}";
      programs._1password-shell-plugins = {
        enable = true;
        plugins = with pkgs; [
          gh
          awscli2
        ];
      };
    };
}
