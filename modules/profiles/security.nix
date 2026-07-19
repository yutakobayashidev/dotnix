{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "security";

  nixos.hardware.ledger.enable = true;

  home =
    { lib, pkgs, ... }:

    {
      home.packages =
        with pkgs;
        lib.optionals pkgs.stdenv.isLinux [
          ledger-live-desktop
          pam_u2f
          pamtester
          yubikey-manager
          yubioath-flutter
        ];
    };
}
