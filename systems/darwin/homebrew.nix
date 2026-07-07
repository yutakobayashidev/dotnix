{
  homebrew = {
    enable = true;
    onActivation = {
      # Workaround for https://github.com/zhaofengli/nix-homebrew/issues/131
      autoUpdate = false;
      cleanup = "uninstall";
      extraFlags = [ "--force-cleanup" ];
    };
    taps = [
      "blacktop/tap"
      "steipete/tap"
      "trasta298/tap"
      "matthart1983/tap"
      "Arthur-Ficial/tap"
    ];
    brews = [
      "blacktop/tap/ipsw"
      "mas"
      "trasta298/tap/keifu"
      "matthart1983/tap/netwatch"
      "Arthur-Ficial/tap/bgbgone"

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
      "karabiner-elements"
      "bettertouchtool"
      "elgato-stream-deck"
      "gpg-suite"

      "blackhole-2ch"
      "nani"
      "nextcloud"
      "nordvpn"
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

      # Hardware
      "ledger-wallet"
      "qmk-toolbox"

      # Media
      "mixxx"
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

      # Gaming
      "modrinth"

      # Other
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
