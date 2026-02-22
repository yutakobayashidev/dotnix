{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      inter
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      hackgen-nf-font
    ];
  };
}
