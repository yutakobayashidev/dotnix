{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "communication";

  home =
    { lib, pkgs, ... }:

    {
      home.packages =
        with pkgs;
        lib.optionals pkgs.stdenv.isLinux [
          discord
          google-chrome
          halloy
          signal-desktop
          slack
          vesktop
        ];
    };
}
