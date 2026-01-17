# YubiKey設定
{ pkgs, ... }:

{
  # YubiKey基本サポート
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.pcscd.enable = true;

  # U2F PAM設定
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      origin = "pam://nixos";
      appid = "pam://nixos";
    };
  };

  # polkitでU2F認証を有効化（1Password用）
  security.pam.services.polkit-1.u2fAuth = true;

  # hyprlockでU2F認証を有効化
  security.pam.services.hyprlock.u2fAuth = true;
}
