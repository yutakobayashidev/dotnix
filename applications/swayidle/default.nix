{ pkgs, ... }:
let
  lockScreen = pkgs.writeShellScript "swayidle-lock" ''
    ${pkgs.playerctl}/bin/playerctl --all-players pause
    ${pkgs.swaylock-effects}/bin/swaylock -f
  '';
in
{
  services.swayidle = {
    enable = true;
    events = {
      # スリープ前にロック
      before-sleep = "${lockScreen}";
      # ロック時に画面オン
      lock = "${lockScreen}";
    };
    timeouts = [
      # 5分後: 画面を暗くする
      {
        timeout = 300;
        command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
        resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
      }
      # 15分後: セッションをロック
      {
        timeout = 900;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      # 30分後: サスペンド
      {
        timeout = 1800;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };

}
