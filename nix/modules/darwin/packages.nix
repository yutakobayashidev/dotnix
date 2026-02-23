# macOS固有パッケージ
# brew-nix: Homebrew cask を Nix パッケージとして管理（バージョン固定・ロールバック可能）
# /Applications へのインストールが必須な cask は homebrew.nix で管理
{ pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      # macOS CLI tools
      terminal-notifier
      coreutils
      cocoapods
      watchman
    ]
    # brew-nix casks
    ++ (with pkgs.brewCasks; [
      # Communication
      discord
      element
      mattermost
      nani
      signal
      simplex
      slack
      telegram
      wechat

      # AI / LLM
      chatgpt

      # Productivity
      anki
      figma
      linear-linear
      notion-calendar
      obsidian

      # Development
      proxyman
      tableplus

      # Media
      vlc
      ogdesign-eagle

      # Utilities
      appcleaner
      raycast
      screen-studio
      stats
      yubico-authenticator

      # Other
      sidequest
      zoom
    ]);
}
