{ pkgs, ... }:

{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # ロック画面コマンド
        before_sleep_cmd = "loginctl lock-session"; # サスペンド前にロック
        after_sleep_cmd = "hyprctl dispatch dpms on"; # 復帰後にディスプレイオン
      };

      listener = [
        {
          timeout = 300; # 5分
          on-timeout = "brightnessctl -s set 10"; # 画面を暗くする
          on-resume = "brightnessctl -r"; # 元の明るさに戻す
        }
        {
          timeout = 600; # 10分
          on-timeout = "hyprctl dispatch dpms off"; # ディスプレイをオフ
          on-resume = "hyprctl dispatch dpms on"; # ディスプレイをオン
        }
        {
          timeout = 900; # 15分
          on-timeout = "loginctl lock-session"; # セッションをロック
        }
        {
          timeout = 1800; # 30分
          on-timeout = "systemctl suspend"; # サスペンド
        }
      ];
    };
  };
}
