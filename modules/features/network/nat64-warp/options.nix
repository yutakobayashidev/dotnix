{ lib, ... }:
let
  iface = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9_.-]{0,14}";
in
{
  options.my.services.nat64Warp = {
    enable = lib.mkEnableOption "routed NAT64 MicroVM (requires separate deployment approval)";
    lanInterface = lib.mkOption {
      type = iface;
      default = "wlp2s0f0u5";
      description = "Historical B450M interface; verify before deployment.";
    };
    tapInterface = lib.mkOption {
      type = iface;
      default = "nat64-tap";
    };
    clients = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "[0-9a-fA-F:]+/[0-9]+");
      default = [ ];
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Public SSH keys for guest administration from the host TAP address.";
    };
    rio.enable = lib.mkEnableOption "LAN RIO advertisement; only after AP/client validation";
    warp.enable = lib.mkEnableOption "WARP exit in guest; NAT64-only baseline when false";
  };
}
