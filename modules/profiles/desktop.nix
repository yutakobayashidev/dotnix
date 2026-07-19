{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "desktop";

  nixos = {
    my.services.tailscale.configureResolver = lib.mkDefault true;
  };
}
