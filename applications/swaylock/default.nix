{ pkgs, ... }:

{
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # 背景設定（スクリーンショットにブラー）
      screenshots = true;
      effect-blur = "8x3";

      # グレース期間
      grace = 10;
      grace-no-mouse = true;
      grace-no-touch = true;

      # フェード効果
      fade-in = 0.2;

      # インジケーター設定
      indicator = true;
      indicator-idle-visible = true;
      indicator-radius = 100;
      indicator-thickness = 7;

      # カラー設定（Catppuccin風）
      ring-color = "494d64";
      ring-ver-color = "f5bde6";
      ring-wrong-color = "ed8796";
      ring-clear-color = "8aadf4";

      key-hl-color = "f5bde6";
      separator-color = "00000000";

      inside-color = "24273a99";
      inside-ver-color = "24273a99";
      inside-wrong-color = "24273a99";
      inside-clear-color = "24273a99";

      text-color = "cad3f5";
      text-ver-color = "cad3f5";
      text-wrong-color = "ed8796";
      text-clear-color = "8aadf4";

      # テキスト設定
      font = "Noto Sans CJK JP";
      font-size = 24;
      text-ver = "VERIFYING";
      text-wrong = "ACCESS DENIED";
      text-clear = "CLEARED";
      text-caps-lock = "CAPS LOCK";

      # 時計設定
      clock = true;
      timestr = "%H:%M";
      datestr = "%Y.%m.%d";
      time-color = "cad3f5";
      date-color = "b7bdf8";
      time-size = 48;
      date-size = 16;

      # カーソル非表示
      hide-keyboard-layout = false;
      show-failed-attempts = true;

      text-caps-lock-color = "eed49f";
    };
  };
}
