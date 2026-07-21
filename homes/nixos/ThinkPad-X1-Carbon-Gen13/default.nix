{ inputs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        ../../desktop.nix
        ../../../applications/course-cli
        ../desktop.nix
        inputs.onepassword-shell-plugins.hmModules.default
      ];
      home.homeDirectory = "/home/${username}";
      home.packages = with pkgs; [
        alcom
        beatoraja
        blender
        osu-lazer-bin
        tetrio-desktop
        unityhub
        vrc-get
        vrcx
      ];
      my.programs.mcp.ghidra.enable = true;
      services.poweralertd.enable = true;
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
