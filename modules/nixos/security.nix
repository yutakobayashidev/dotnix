{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  yubiCfg = config.ext.security.yubikey;
  sbCfg = config.ext.security.secureboot;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.ext.security = {
    yubikey = {
      enable = lib.mkEnableOption "YubiKey PAM/U2F support";

      allowRemotePolkit = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

    secureboot = {
      enable = lib.mkEnableOption "Secure boot with lanzaboote";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf yubiCfg.enable {
      services.udev.packages = [ pkgs.yubikey-personalization ];

      security = {
        pam = {
          u2f = {
            enable = true;
            control = "sufficient";
            settings = {
              origin = "pam://${config.networking.hostName}";
              appid = "pam://${config.networking.hostName}";
            };
          };
          services = {
            polkit-1.u2fAuth = true;
            swaylock.u2fAuth = true;
          };
        };

        polkit.extraConfig = lib.optionalString yubiCfg.allowRemotePolkit ''
          polkit.addRule(function(action, subject) {
            if (subject.isInGroup("wheel") && subject.local == false) {
              return polkit.Result.YES;
            }
          });
        '';
      };
    })
    (lib.mkIf sbCfg.enable {
      environment.systemPackages = [ pkgs.sbctl ];

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      boot.loader.systemd-boot.enable = false;
    })
  ];
}
