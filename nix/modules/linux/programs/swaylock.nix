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
      indicator-radius = 100;
      indicator-thickness = 7;

      # カラー設定（Catppuccin風）
      ring-color = "5b6078";
      ring-ver-color = "f5bde6";
      ring-wrong-color = "f38ba8";
      ring-clear-color = "89b4fa";

      key-hl-color = "f5bde6";
      separator-color = "00000000";

      inside-color = "1e1e2e80";
      inside-ver-color = "1e1e2e80";
      inside-wrong-color = "1e1e2e80";
      inside-clear-color = "1e1e2e80";

      text-color = "cad3f5";
      text-ver-color = "cad3f5";
      text-wrong-color = "f38ba8";
      text-clear-color = "89b4fa";

      # テキスト設定
      font = "Noto Sans CJK JP";
      font-size = 24;

      # カーソル非表示
      hide-keyboard-layout = false;
      show-failed-attempts = true;

      # カスタムテキスト
      text-caps-lock-color = "f9e2af";
    };
  };
}
