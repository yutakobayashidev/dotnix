{
  pkgs,
  lib,
  config,
  username,
  ...
}:

{
  imports = [
    ./homebrew.nix
  ];

  system = {
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
        persistent-apps =
          let
            inherit (config.home-manager.users.${username}) programs;
          in
          [ "${programs.firefox.package}/Applications/Firefox.app" ]
          ++ [ "${pkgs.ghostty-bin}/Applications/Ghostty.app" ];
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

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  my.services.azookey.enable = true;

  power = {
    restartAfterFreeze = true;
    sleep.allowSleepByPowerButton = true;
  };

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      inter
      stable.jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      hackgen-nf-font
      mplus-outline-fonts.githubRelease
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';
}
