{ config, lib, ... }:
let
  cfg = config.my.services.azookey;
in
{
  options.my.services.azookey = {
    enable = lib.mkEnableOption "azooKey Japanese input method";
  };

  config = lib.mkIf cfg.enable {
    system.defaults.inputsources.AppleEnabledThirdPartyInputSources = [
      {
        "Bundle ID" = "dev.ensan.inputmethod.azooKeyMac";
        InputSourceKind = "Keyboard Input Method";
      }
      {
        "Bundle ID" = "dev.ensan.inputmethod.azooKeyMac";
        "Input Mode" = "com.apple.inputmethod.Roman";
        InputSourceKind = "Input Mode";
      }
      {
        "Bundle ID" = "dev.ensan.inputmethod.azooKeyMac";
        "Input Mode" = "com.apple.inputmethod.Japanese";
        InputSourceKind = "Input Mode";
      }
    ];
  };
}
