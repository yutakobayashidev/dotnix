# Hyprland設定
{ ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Greetd + ReGreet
  services.greetd.enable = true;
  programs.regreet.enable = true;
}
