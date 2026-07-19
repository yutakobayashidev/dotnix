{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "communication";

  nixos.services.kbfs.enable = true;

  home =
    { lib, pkgs, ... }:

    {
      home.packages =
        with pkgs;
        lib.optionals pkgs.stdenv.isLinux [
          discord
          element-desktop
          google-chrome
          halloy
          keybase-gui
          mattermost-desktop
          signal-desktop
          simplex-chat-desktop
          slack
          telegram-desktop
          vesktop
          wechat
        ];
    };
}
