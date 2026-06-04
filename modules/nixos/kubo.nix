{ config, lib, ... }:
let
  cfg = config.my.services.kubo;
in
{
  options.my.services.kubo.enable = lib.mkEnableOption "Kubo IPFS node";

  config = lib.mkIf cfg.enable {
    services.kubo.enable = true;
  };
}
