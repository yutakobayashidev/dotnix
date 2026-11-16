{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.services.nat64Warp;
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ./host.nix
    ./options.nix
  ];
  config = lib.mkMerge [
    {
      microvm.host.enable = lib.mkDefault (cfg.enable || config.microvm.vms != { });
    }
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !cfg.warp.enable || cfg.authorizedKeys != [ ];
          message = "WARP requires an explicit guest administration public key for manual enrollment.";
        }
      ];
      microvm.vms.nat64 = {
        autostart = true;
        pkgs = null;
        config = {
          imports = [ ./guest.nix ];
          networking.hostName = "nat64";
          system.stateVersion = "26.05";
          nixpkgs.config.allowUnfree = true;
          microvm = {
            hypervisor = "qemu";
            vcpu = 2;
            mem = 1024;
            interfaces = [
              {
                type = "tap";
                id = cfg.tapInterface;
                mac = "02:64:00:00:35:02";
              }
            ];
            shares = [
              {
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                tag = "ro-store";
                proto = "virtiofs";
              }
            ];
            volumes = [
              {
                image = "state.img";
                mountPoint = "/var";
                size = 1024;
              }
            ];
          };
          networking = {
            useDHCP = false;
            usePredictableInterfaceNames = false;
            interfaces.eth0 = {
              ipv4.addresses = [
                {
                  address = "192.168.254.2";
                  prefixLength = 30;
                }
              ];
              ipv6.addresses = [
                {
                  address = "fd64:35::2";
                  prefixLength = 64;
                }
              ];
            };
            defaultGateway = {
              address = "192.168.254.1";
              interface = "eth0";
            };
            nameservers = [
              "9.9.9.9"
              "1.1.1.1"
            ];
          };
          services.openssh = lib.mkIf (cfg.authorizedKeys != [ ]) {
            enable = true;
            openFirewall = false;
            listenAddresses = [
              {
                addr = "192.168.254.2";
                port = 22;
              }
            ];
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
            };
          };
          networking.firewall.interfaces.eth0.allowedTCPPorts = lib.mkIf (cfg.authorizedKeys != [ ]) [ 22 ];
          users.users.root.openssh.authorizedKeys.keys = cfg.authorizedKeys;
          my.services.nat64Guest = {
            enable = true;
            inherit (cfg) clients;
            warp.enable = cfg.warp.enable;
          };
        };
      };
      systemd.tmpfiles.settings."10-microvm"."${config.microvm.stateDir}/nat64".d.mode =
        lib.mkForce "0700";
      systemd.services.nat64-host = {
        requires = [ "microvm-tap-interfaces@nat64.service" ];
        after = [ "microvm-tap-interfaces@nat64.service" ];
        partOf = [ "microvm@nat64.service" ];
      };
      systemd.services."microvm@nat64" = {
        requires = [ "nat64-host.service" ];
        after = [ "nat64-host.service" ];
      };
    })
  ];
}
