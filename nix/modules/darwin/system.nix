{ username, ... }:

{
  system = {
    primaryUser = username;
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
        _FXShowPosixPathInTitle = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      LaunchServices = {
        LSQuarantine = false;
      };

      WindowManager.EnableStandardClickToShowDesktop = false;

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

    activationScripts.extraActivation.text = ''
      softwareupdate --all --install
    '';
  };

  time.timeZone = "Asia/Tokyo";

  system.startup.chime = false;

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  power = {
    restartAfterFreeze = true;
    sleep.allowSleepByPowerButton = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
}
