{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "desktop";

  nixos = {
    services.gnome.at-spi2-core.enable = lib.mkDefault true;
    my.programs.handy.enable = lib.mkDefault true;
    my.services.tailscale.configureResolver = lib.mkDefault true;
  };

  home =
    { lib, pkgs, ... }:
    {
      my.programs = {
        agent-desktop.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
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
