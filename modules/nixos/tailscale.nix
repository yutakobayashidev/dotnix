{ config, lib, ... }:

let
  cfg = config.my.services.tailscale;
in
{
  options.my.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN";

    configureResolver = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable systemd-resolved for Tailscale DNS (desktop systems).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "server";
          authKeyFile = config.sops.secrets.tailscale-authkey.path;
          extraUpFlags = [
            "--ssh"
            "--accept-dns=false"
          ];
        };

        networking = {
          firewall = {
            trustedInterfaces = [ "tailscale0" ];
            allowedUDPPorts = [ config.services.tailscale.port ];
          };
          nameservers = [
            "100.100.100.100"
            "8.8.8.8"
          ];
          search = [ "tail29d068.ts.net" ];
        };

        sops.secrets.tailscale-authkey = { };
      }
      (lib.mkIf cfg.configureResolver {
        services.resolved.enable = true;
      })
    ]
  );
}
