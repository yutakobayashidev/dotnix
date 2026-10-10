_:

let
  palette = import ../../../../lib/desktop-palette.nix;
in
{
  flake.modules.homeManager.swaylock =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.swaylock;
    in
    {
      options.my.programs.swaylock.enable = lib.mkEnableOption "Swaylock";

      config = lib.mkIf cfg.enable {
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

            # カラー設定（Catppuccin Mocha）
            ring-color = palette.surface1;
            ring-ver-color = palette.mauve;
            ring-wrong-color = palette.red;
            ring-clear-color = palette.blue;

            key-hl-color = palette.mauve;
            separator-color = "00000000";

            inside-color = "${palette.base}99";
            inside-ver-color = "${palette.base}99";
            inside-wrong-color = "${palette.base}99";
            inside-clear-color = "${palette.base}99";

            text-color = palette.text;
            text-ver-color = palette.text;
            text-wrong-color = palette.red;
            text-clear-color = palette.blue;

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
            time-color = palette.text;
            date-color = palette.lavender;
            time-size = 48;
            date-size = 16;

            # カーソル非表示
            hide-keyboard-layout = false;
            show-failed-attempts = true;

            text-caps-lock-color = palette.yellow;
          };
        };
      };
    };
}
