{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "desktop";

  nixos = {
    my.programs.handy.enable = lib.mkDefault true;
    my.services.tailscale.configureResolver = lib.mkDefault true;
  };

  home = {
    my.programs.handy.enable = lib.mkDefault true;
  };
}
