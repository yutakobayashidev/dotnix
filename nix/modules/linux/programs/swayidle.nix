{ pkgs, ... }:

{
  services.swayidle = {
    enable = true;
    events = {
      # スリープ前にロック
      before-sleep = "${pkgs.systemd}/bin/loginctl lock-session";
      # ロック時に画面オン
      lock = "${pkgs.swaylock-effects}/bin/swaylock";
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
