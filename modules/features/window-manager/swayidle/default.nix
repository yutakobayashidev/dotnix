_:

{
  flake.modules.homeManager.swayidle =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.swayidle;

      lockScreen = pkgs.writeShellScript "swayidle-lock" ''
        ${pkgs.playerctl}/bin/playerctl --all-players pause
        ${pkgs.swaylock-effects}/bin/swaylock -f
      '';
    in
    {
      options.my.services.swayidle = {
        enable = lib.mkEnableOption "Swayidle";
        suspend.enable = lib.mkEnableOption "automatic suspend after 30 minutes of inactivity";
      };

      config = lib.mkIf cfg.enable {
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
          ]
          ++ lib.optional cfg.suspend.enable {
            # 30分後: サスペンド（ノートPCなどで明示的に有効化）
            timeout = 1800;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          };
        };
      };
    };
}
