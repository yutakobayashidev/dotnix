{ ... }:

{
  system = {
    stateVersion = 6;

    defaults = {
      controlcenter.BatteryShowPercentage = true;

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        NSAutomaticCapitalizationEnabled = false;
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        ShowPathbar = true;
      };

      LaunchServices = {
        LSQuarantine = false;
      };

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        show-recents = false;
        orientation = "bottom";
      };

      screencapture = {
        disable-shadow = true;
        location = "~/Pictures/screenshots";
        type = "jpg";
      };

      CustomSystemPreferences = {
        "com.apple.appleseed" = {
          "FeedbackAssistant.Autogather" = false;
        };
        "com.apple.CrashReporter" = {
          DialogType = "none";
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.AppleMultitouchTrackpad" = {
          Clicking = true;
        };
        "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
          Clicking = true;
        };
        "com.apple.trackpad" = {
          scaling = 1.5;
        };
        "com.apple.swipescrolldirection" = {
          value = false;
        };
      };
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://cache.numtide.com"
      "https://yuta.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "yuta.cachix.org-1:VGiC7m0kQjut7lp+RG/9pCRHFpzf11ELQrM2Nc2QCCk="
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
}
