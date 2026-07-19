{ inputs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        ../../../modules/profiles/home/development.nix
        ../../../modules/profiles/home/communication.nix
        ../../../modules/profiles/home/media.nix
        ../../../modules/profiles/home/productivity.nix
        ../../../modules/profiles/home/security.nix
        ../../../modules/profiles/home/network.nix
        ../../desktop.nix
        ../../../applications/course-cli
        ../desktop.nix
        inputs.onepassword-shell-plugins.hmModules.default
      ];
      home.homeDirectory = "/home/${username}";
      services.wallpaper.imagePath = "/home/${username}/wallpapers/lycoris-recoil-rain.jpg";
      programs._1password-shell-plugins = {
        enable = true;
        plugins = with pkgs; [
          gh
          awscli2
        ];
      };
      programs.niri.settings.input.touchpad = {
        accel-speed = -0.2;
        natural-scroll = true;
      };
    };
}
