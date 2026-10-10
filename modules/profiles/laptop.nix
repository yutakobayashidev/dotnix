{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "laptop";

  nixos = {
    my.system.camera.enable = lib.mkDefault true;
  };

  home =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      my.services.swayidle.suspend.enable = lib.mkDefault true;
    };
}
