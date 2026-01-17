# Hyprland home-manager設定
{ pkgs, ... }:

{
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.settings = import ./programs/hyprland.nix { inherit pkgs; };
  wayland.windowManager.hyprland.extraConfig = ''
    windowrule {
      name = spotify-to-scratchpad
      match:class = Spotify
      workspace = special:magic silent
    }
  '';
}
