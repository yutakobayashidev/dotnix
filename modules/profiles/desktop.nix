{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "desktop";

  nixos = {
    my.programs.handy.enable = lib.mkDefault true;
    my.services.tailscale.configureResolver = lib.mkDefault true;
  };

  home =
    { lib, pkgs, ... }:
    {
      my.programs.handy.enable = lib.mkDefault true;
      my.programs.orca.enable = lib.mkDefault true;

      home.packages = lib.optionals pkgs.stdenv.isLinux (
        with pkgs;
        [
          brightnessctl
          nautilus
          rpi-imager
        ]
      );
    };
}
