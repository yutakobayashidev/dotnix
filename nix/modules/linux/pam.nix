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

  # swaylockでU2F認証を有効化
  security.pam.services.swaylock.u2fAuth = true;

  # SSH経由（リモートセッション）の場合はpolkit認証を自動承認
  # パスワード認証（PAM）は通常通り必要
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      // wheelグループ + リモートセッション（SSH）の場合は自動承認
      if (subject.isInGroup("wheel") && subject.local == false) {
        return polkit.Result.YES;
      }
    });
  '';
}
