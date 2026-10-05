{ inputs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        ../../desktop.nix
        ../desktop.nix
        inputs.onepassword-shell-plugins.hmModules.default
      ];
      my.programs.course-cli.enable = true;
      my.programs.nlobby-cli.enable = true;
      home.homeDirectory = "/Users/${username}";
      home.packages = with pkgs.brewCasks; [
        alcom
        blender
      ];
      programs._1password-shell-plugins = {
        enable = true;
        plugins = with pkgs; [
          gh
          awscli2
          tea
        ];
      };
    };
}
