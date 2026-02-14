# niri設定
{ ... }:

{
  programs.niri = {
    enable = true;
  };

  # XWayland サポート
  programs.xwayland.enable = true;

  # Greetd + ReGreet
  services.greetd.enable = true;
  programs.regreet.enable = true;
}
