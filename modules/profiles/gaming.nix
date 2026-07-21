{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "gaming";

  home =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        lutris
        protonup-qt
        wineWow64Packages.stable
        winetricks
      ];
    };
}
