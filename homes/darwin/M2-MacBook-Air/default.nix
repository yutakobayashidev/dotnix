{ inputs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        ../../../modules/profiles/home/cli.nix
        ../../../modules/profiles/home/development.nix
        ../../../modules/profiles/home/desktop.nix
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
