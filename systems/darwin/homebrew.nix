{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    taps = [
      "blacktop/tap"
      "manaflow-ai/cmux"
      "steipete/tap"
      "trasta298/tap"
    ];
    brews = [
      "blacktop/tap/ipsw"
      "mas"
      "trasta298/tap/keifu"

      # vphone-cli dependencies
      "gnu-tar"
      "openssl@3"
      "ldid-procursus"
      "sshpass"
      "keystone"
      "autoconf"
      "automake"
      "pkg-config"
      "libtool"
      "cmake"
      "python@3.13"
      "ideviceinstaller"
      "libimobiledevice"
      "libplist"
      "libimobiledevice-glue"
      "libtasn1"
      "libtatsu"
      "libusbmuxd"
      "ca-certificates"
    ];
    casks = [
      # System Integration
      "1password"
      "karabiner-elements"
      "bettertouchtool"
      "elgato-stream-deck"
      "gpg-suite"
      "orbstack"
      "blackhole-2ch"
      "nani"
      "nextcloud"
      "telegram"
      "azookey"

      # Browsers
      "chromium"
      "google-chrome"

      # Complex installers
      "adobe-acrobat-reader"
      "adobe-creative-cloud"
      "android-studio"
      "google-drive"
      "maxon"
      "microsoft-auto-update"
      "qgis"
      "visual-studio-code"

      # Hardware
      "ledger-wallet"
      "qmk-toolbox"

      # Media
      "obs"
      "krita"
      "spotify"

      # AI / LLM
      "claude"
      "codex-app"
      "codexbar"
      "lm-studio"
      "windows-app"

      # VR
      "unity-hub"
      "virtual-desktop-streamer"

      # Other
      "cmux"
      "bitcoin-core"
      "keybase"
      "raycast"
      "tor-browser"
    ];

    masApps = {
      "Xcode" = 497799835;
      "Developer" = 640199958;
      "Kindle" = 302584613;
      "Keynote" = 409183694;
      "RunCat" = 1429033973;
      "TestFlight" = 899247664;
      "DaVinci Resolve" = 571213070;
      "Pages" = 409201541;
      "GarageBand" = 682658836;
      "Numbers" = 409203825;
    };
  };
}
