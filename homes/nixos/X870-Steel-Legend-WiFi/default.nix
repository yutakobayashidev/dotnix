{ pkgs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../desktop.nix
      ../desktop.nix
    ];
    home.packages = with pkgs; [
      alcom
      android-tools
      beatoraja
      blender
      bs-manager
      davinci-resolve
      lmstudio
      modrinth-app
      osu-lazer-bin
      (prismlauncher.override {
        jdks = [
          jdk25
          jdk21
          jdk17
          jdk8
        ];
      })
      sidequest
      tetrio-desktop
      unityhub
      vrc-get
      vrcx
      wayvr
    ];
    home.homeDirectory = "/home/${username}";
  };
}
