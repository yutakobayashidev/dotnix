{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "laptop";

  nixos = {
    my.system.camera.enable = lib.mkDefault true;
  };
}
