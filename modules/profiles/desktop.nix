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
      my.programs = {
        chatgpt.enable = lib.mkDefault true;
        claude-desktop.enable = lib.mkDefault true;
        grok-bot.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        handy.enable = lib.mkDefault true;
        herdr-app.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        hermes-desktop.enable = lib.mkDefault true;
      };

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
