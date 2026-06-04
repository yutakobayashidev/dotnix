# macOS-specific Home Manager packages.
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
      prismlauncher

      # macOS CLI tools
      terminal-notifier
      coreutils
      cocoapods
    ]
    ++ (with pkgs.brewCasks; [
      # Communication
      discord
      element
      mattermost
      signal
      simplex
      slack
      wechat

      # AI / LLM
      chatgpt

      # Productivity
      anki
      figma
      synthesia
      linear
      notion-calendar

      # Development
      proxyman
      tableplus

      # Media
      vlc
      ogdesign-eagle

      # Utilities
      appcleaner
      screen-studio
      stats
      yubico-authenticator

      # Hardware
      arduino-ide

      # Gaming
      modrinth-app

      # Other
      ipfs-desktop
      sidequest
      zoom
    ]);
}
