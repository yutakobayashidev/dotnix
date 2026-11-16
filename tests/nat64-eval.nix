{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  common = {
    system.stateVersion = "26.05";
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
    };
    networking.hostName = "nat64-evaluation";
  };
  evaluate =
    modules:
    inputs.nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      specialArgs = { inherit inputs; };
      modules = [ common ] ++ modules;
    };
  baseline = evaluate [ ];
  disabled = evaluate [
    ../modules/features/network/nat64-warp/module.nix
    ../modules/features/network/nat64-warp/dns64.nix
  ];
  enabled = evaluate [
    ../modules/features/network/nat64-warp/module.nix
    {
      my.services.nat64Warp = {
        enable = true;
        clients = [ "2001:db8:1::10/128" ];
        warp.enable = true;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        ];
      };
    }
  ];
  guest = enabled.config.microvm.vms.nat64.config.config;
in
assert
  baseline.config.system.build.toplevel.drvPath == disabled.config.system.build.toplevel.drvPath;
assert !disabled.config.my.services.dns64.enable;
assert !disabled.config.my.services.nat64Warp.rio.enable;
assert !enabled.config.services.radvd.enable;
assert guest.services.cloudflare-warp.enable;
assert guest.system.build.toplevel.drvPath != "";
assert enabled.config.system.build.toplevel.drvPath != "";
pkgs.runCommand "nat64-evaluation-test" { } "touch $out"
