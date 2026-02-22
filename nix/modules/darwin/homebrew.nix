{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
    };
    # /Applications への直接インストールやシステム統合が必要な cask
    # brew-nix で管理可能なものは packages-darwin.nix に移動済み
    casks = [
      # System Integration (カーネル拡張・システムサービス)
      "1password"
      "karabiner-elements"
      "bettertouchtool"
      "elgato-stream-deck"
      "gpg-suite"
      "orbstack"
      "tailscale"
      "blackhole-2ch"

      # Browsers (システム統合が深い)
      "google-chrome"

      # Complex Installers (pkg/独自インストーラー)
      "adobe-acrobat-reader"
      "adobe-creative-cloud"
      "android-studio"
      "ghostty"
      "google-cloud-sdk"
      "microsoft-auto-update"
      "qgis"

      # Hardware
      "arduino-ide"
      "ledger-live"
      "qmk-toolbox"

      # Other
      "bitcoin-core"
      "sidequest"
      "virtual-desktop-streamer"
    ];

    # Mac App Store (mas で管理)
    masApps = {
      "Xcode" = 497799835;
      "Developer" = 640199958;
      "Keynote" = 409183694;
      "RunCat" = 1429033973;
      "TestFlight" = 899247664;
      "DaVinci Resolve" = 571213070;
      "Pages" = 409201541;
      "GarageBand" = 682658836;
      "Numbers" = 409203825;
      # Telegram は brew-nix (packages-darwin.nix) で管理
    };
  };
}
