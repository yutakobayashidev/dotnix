# macOS固有パッケージ
# brew-nix: Homebrew cask を Nix パッケージとして管理（バージョン固定・ロールバック可能）
# /Applications へのインストールが必須な cask は homebrew.nix で管理
{ pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      # Terminal
      ghostty-bin
      difit

      # macOS apps (overlay)
      readout

      # macOS CLI tools
      terminal-notifier
      coreutils
      cocoapods
      watchman

      # Build tools
      gnutar
      openssl
      ldid
      sshpass
      keystone
      autoconf
      automake
      pkg-config
      libtool
    ]
    # brew-nix casks
    ++ (with pkgs.brewCasks; [
      # Communication
      discord
      element
      mattermost
      # nani # TODO: upstream download URL returns 404
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

      # Hardware
      arduino-ide

      # Other
      sidequest
      zoom
    ]);
}
