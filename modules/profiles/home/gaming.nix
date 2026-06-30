{ lib, pkgs, ... }:

{
  home.packages =
    (with pkgs; [
      beatoraja
      bs-manager
      lutris
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
      protonup-qt
      tetrio-desktop
      vrc-get
      wayvr
      wineWow64Packages.stable
      winetricks
    ])
    ++ lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        alcom
        blender
        unityhub
        vrcx
      ]
    )
    ++ lib.optionals pkgs.stdenv.isDarwin (
      with pkgs.brewCasks;
      [
        alcom
        blender
      ]
    );
}
