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
      "cleanmymac"
      "cloudflare-warp"
      "elgato-stream-deck"
      "gpg-suite"
      "orbstack"
      "tailscale"
      "blackhole-2ch"

      # Browsers (システム統合が深い)
      "google-chrome"
      "microsoft-edge"

      # Complex Installers (pkg/独自インストーラー)
      "adobe-acrobat-reader"
      "adobe-creative-cloud"
      "android-studio"
      "ghostty"
      "google-cloud-sdk"
      "microsoft-auto-update"
      "nvidia-geforce-now"
      "rstudio"

      # Hardware
      "arduino-ide"
      "ledger-live"
      "qmk-toolbox"

      # Other
      "amazon-q"
      "bitcoin-core"
      "local"
      "sidequest"
      "virtual-desktop-streamer"
    ];

    # Mac App Store (mas で管理)
    masApps = {
      # 必要に応じて追加
      # "App Name" = APP_STORE_ID;
    };
  };
}
