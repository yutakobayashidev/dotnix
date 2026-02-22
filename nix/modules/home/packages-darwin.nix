# macOS固有パッケージ
# brew-nix: Homebrew cask を Nix パッケージとして管理（バージョン固定・ロールバック可能）
# /Applications へのインストールが必須な cask は homebrew.nix で管理
{ pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      # macOS CLI tools
      mas
      terminal-notifier
      coreutils
      cocoapods
      watchman
    ]
    # brew-nix casks
    ++ (with pkgs.brewCasks; [
      # Browsers
      arc
      firefox

      # Communication
      discord
      discord-canary
      element
      halloy
      mattermost
      messenger
      signal
      simplex
      slack
      wechat

      # AI / LLM
      chatgpt
      cursor
      diffusionbee
      ollama
      superwhisper

      # Productivity
      anki
      deepl
      figma
      linear-linear
      notion
      notion-calendar
      obsidian
      readdle-spark
      mimestream

      # Development
      bruno
      ngrok
      postman
      proxyman
      tableplus
      visual-studio-code
      webstorm
      zed

      # Media
      obs
      spotify
      vlc
      krita
      ogdesign-eagle

      # Utilities
      appcleaner
      raycast
      warp
      hyper
      stats

      # Gaming
      epic-games
      minecraft
      osu
      parsec
      steam

      # Other
      dropbox
      keybase
      tor-browser
      zoom
    ]);
}
