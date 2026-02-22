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

      # Productivity
      anki
      figma
      linear-linear
      notion
      notion-calendar
      obsidian
      readdle-spark

      # Development
      ngrok
      proxyman
      tableplus
      visual-studio-code

      # Media
      spotify
      vlc
      krita
      ogdesign-eagle

      # Utilities
      appcleaner
      raycast
      stats

      # Gaming
      epic-games
      parsec
      steam

      # Other
      keybase
      tor-browser
      zoom
    ]);
}
