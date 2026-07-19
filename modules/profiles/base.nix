{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "base";

  system = {
    my.nix.enable = lib.mkDefault true;
    my.nixpkgs = {
      enable = lib.mkDefault true;
      permittedInsecurePackages = lib.mkDefault [
        "python3.14-ecdsa-0.19.2"
      ];
    };
  };

  nixos = {
    my.services.tailscale.enable = lib.mkDefault true;
    nixpkgs.config.android_sdk.accept_license = true;
  };

  darwin = {
    services.tailscale.enable = lib.mkDefault true;
  };

  home = {
    my.programs.dotfiles.enable = lib.mkDefault true;
    my.programs.zsh.enable = lib.mkDefault true;
  };
}
