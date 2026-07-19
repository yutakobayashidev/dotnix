{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "gaming";

  home =
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
            android-tools
            blender
            sidequest
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
    };
}
