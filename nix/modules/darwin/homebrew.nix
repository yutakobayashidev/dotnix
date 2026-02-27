{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    taps = [
      "manaflow-ai/cmux"
      "trasta298/tap"
    ];
    brews = [
      "mas"
      "trasta298/tap/keifu"
    ];
    # /Applications への直接インストールやシステム統合が必要な cask
    # brew-nix で管理可能なものは packages.nix に移動済み
    casks = [
      # System Integration (カーネル拡張・システムサービス)
      "1password"
      "karabiner-elements"
      "bettertouchtool"
      "elgato-stream-deck"
      "gpg-suite"
      "orbstack"
      "tailscale-app"
      "blackhole-2ch"

      # Browsers (システム統合が深い)
      "google-chrome"

      # Complex Installers (pkg/独自インストーラー)
      "adobe-acrobat-reader"
      "adobe-creative-cloud"
      "android-studio"
      "microsoft-auto-update"
      "qgis"

      # Hardware
      "ledger-wallet"
      "qmk-toolbox"

      # Media (brew-nix のビルドが壊れているため cask で管理)
      "krita"
      "spotify"

      # AI / LLM
      "claude"

      # VR (brew-nix のハッシュが壊れているため cask で管理)
      "virtual-desktop-streamer"

      # Other
      "cmux"
      "bitcoin-core"
      "keybase"
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
