{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "security";

  home =
    { lib, pkgs, ... }:

    {
      home.packages =
        with pkgs;
        lib.optionals pkgs.stdenv.isLinux [
          pam_u2f
          pamtester
          yubikey-manager
          yubioath-flutter
        ];
    };
}
