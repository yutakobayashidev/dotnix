{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "catppuccin_macchiato";
      theme_background = false;
      truecolor = true;
      rounded_corners = true;
      update_ms = 1000;
    };
  };

  xdg.configFile."btop/themes/catppuccin_macchiato.theme".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_macchiato.theme";
    sha256 = "sha256-+LGMyyF71OvBhIBqkdSaEssxK5zzfYuiMyJlOnisiFA=";
  };
}
