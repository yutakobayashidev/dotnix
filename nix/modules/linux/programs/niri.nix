# niri home-manager設定
{ pkgs, inputs, ... }:

{
  imports = [ inputs.niri.homeModules.niri ];
  # niri パッケージをテストスキップでオーバーライド
  programs.niri.package = pkgs.niri.overrideAttrs (oldAttrs: {
    doCheck = false;
  });

  programs.niri.settings = {
    # タイトルバーを非表示
    prefer-no-csd = true;

    # 入力設定
    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        tap = true;
        natural-scroll = false;
      };
      mouse.accel-speed = 0.0;
    };

    # 出力設定（モニター）
    outputs."eDP-1".scale = 1.5;

    # レイアウト設定
    layout = {
      gaps = 16;
      center-focused-column = "never";
      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      default-column-width = {
        proportion = 0.5;
      };

      # フォーカスリング（アクティブウィンドウを強調）
      focus-ring = {
        width = 2;
        active.color = "#f5bde6"; # Catppuccin ピンク
        inactive.color = "#5b6078"; # Catppuccin グレー
      };

      # ボーダー
      border = {
        width = 2;
        active.color = "#f5bde6";
        inactive.color = "#5b6078";
      };
    };

    # 環境変数
    environment.XCURSOR_SIZE = "24";

    # 自動起動
    spawn-at-startup = [
      { command = [ "swww-daemon" ]; }
      {
        command = [
          "sh"
          "-c"
          "sleep 1 && swww img ~/wallpapers/wp13990714.png --transition-type fade"
        ];
      }
      {
        command = [
          "fcitx5"
          "-d"
        ];
      }
      { command = [ "waybar" ]; }
      { command = [ "spotify" ]; }
      {
        command = [
          "wl-paste"
          "--watch"
          "cliphist"
          "store"
        ];
      }
    ];

    # キーバインド
    binds = {
      "Mod+Q".action.spawn = [ "ghostty" ];
      "Mod+C".action.close-window = { };
      "Mod+M".action.quit = { };
      "Mod+E".action.spawn = [ "dolphin" ];
      "Mod+V".action.spawn = [
        "sh"
        "-c"
        "cliphist list | rofi -dmenu | cliphist decode | wl-copy"
      ];
      "Mod+R".action.spawn = [
        "rofi"
        "-show"
        "drun"
      ];
      "Mod+Shift+F".action.toggle-window-floating = { };

      # フォーカス移動
      "Mod+Left".action.focus-column-left = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };

      # ウィンドウ移動
      "Mod+Shift+Left".action.move-column-left = { };
      "Mod+Shift+Right".action.move-column-right = { };
      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+L".action.move-column-right = { };

      # ウィンドウサイズ調整
      "Mod+Ctrl+Left".action.set-column-width = "-10%";
      "Mod+Ctrl+Right".action.set-column-width = "+10%";

      # ワークスペース移動
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;

      # ウィンドウをワークスペースに移動
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;

      # スクリーンショット
      "Mod+Shift+S".action.spawn = [
        "grimblast"
        "copy"
        "area"
      ];

      # メディアキー
      "XF86AudioRaiseVolume".action.spawn = [
        "wpctl"
        "set-volume"
        "-l"
        "1"
        "@DEFAULT_AUDIO_SINK@"
        "5%+"
      ];
      "XF86AudioLowerVolume".action.spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "5%-"
      ];
      "XF86AudioMute".action.spawn = [
        "wpctl"
        "set-mute"
        "@DEFAULT_AUDIO_SINK@"
        "toggle"
      ];
      "XF86MonBrightnessUp".action.spawn = [
        "brightnessctl"
        "set"
        "5%+"
      ];
      "XF86MonBrightnessDown".action.spawn = [
        "brightnessctl"
        "set"
        "5%-"
      ];
    };
  };

  # 必要なパッケージ
  home.packages = with pkgs; [
    swww
    rofi
    grimblast
    cliphist
    wl-clipboard
    brightnessctl
    playerctl
    polycat
  ];
}
