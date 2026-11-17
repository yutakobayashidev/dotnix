{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "productivity";

  home =
    { lib, pkgs, ... }:

    {
      home.packages =
        with pkgs;
        lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          libreoffice
          nextcloud-client
          stable.anki
        ];
    };
}
