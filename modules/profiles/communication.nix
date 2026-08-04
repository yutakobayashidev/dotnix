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
          element-desktop
          google-chrome
          halloy
          keybase-gui
          mattermost-desktop
          signal-desktop
          simplex-chat-desktop
          slack
          telegram-desktop
        ];

      programs.vesktop = {
        enable = true;

        settings = {
          discordBranch = "stable";

          hardwareAcceleration = true;
          hardwareVideoAcceleration = true;

          tray = true;
          minimizeToTray = true;

          # Discord Rich Presence
          arRPC = true;

          openLinksWithElectron = false;

          spellCheckLanguages = [
            "ja-JP"
            "en-US"
          ];
        };

        vencord = {
          useSystem = false;

          settings = {
            autoUpdate = true;
            autoUpdateNotification = false;

            useQuickCss = false;

            cloud.settingsSync = false;

            notifications = {
              position = "bottom-right";
              useNative = "not-focused";
              timeout = 5000;
              logLimit = 50;
            };
          };
        };
      };
    };
}
