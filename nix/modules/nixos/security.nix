{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.security.yubikey;
in
{
  options.my.security.yubikey = {
    enable = lib.mkEnableOption "YubiKey PAM/U2F support";

    allowRemotePolkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.packages = [ pkgs.yubikey-personalization ];

    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        origin = "pam://${config.networking.hostName}";
        appid = "pam://${config.networking.hostName}";
      };
    };

    security.pam.services.polkit-1.u2fAuth = true;
    security.pam.services.swaylock.u2fAuth = true;

    security.polkit.extraConfig = lib.optionalString cfg.allowRemotePolkit ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel") && subject.local == false) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
