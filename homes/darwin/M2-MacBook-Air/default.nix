{ inputs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
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
