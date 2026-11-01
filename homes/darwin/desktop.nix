# macOS-specific Home Manager packages.
{ pkgs, ... }:

{
  my.programs.emacs.enable = true;
  my.programs.difit.enable = true;

  home.packages =
    with pkgs;
    [
      # Terminal
      ghostty-bin

      # macOS apps (overlay)
      readout
      prismlauncher

      # macOS CLI tools
      terminal-notifier
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

      # Other
      ipfs-desktop
      sidequest
      zoom
    ]);
}
