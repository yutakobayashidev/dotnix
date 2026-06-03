{
  config,
  lib,
  pkgs,
  ...
}:

let
  netbootEval = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    system = pkgs.stdenv.hostPlatform.system;
    modules = [
      "${pkgs.path}/nixos/modules/installer/netboot/netboot-minimal.nix"
      ../../../../nix/modules/profiles/nixos/installer.nix
      {
        system.stateVersion = config.system.nixos.release;
        nixpkgs.pkgs = lib.mkForce pkgs;
      }
    ];
  };

  build = netbootEval.config.system.build;
  kernelTarget = netbootEval.pkgs.stdenv.hostPlatform.linux-kernel.target;
  kernel = "${build.kernel}/${kernelTarget}";
  initrd = "${build.netbootRamdisk}/initrd";
  cmdline = "init=${build.toplevel}/init loglevel=4";
in
{
  networking.firewall.allowedUDPPorts = [
    67
    69
    4011
  ];

  systemd.services.pixiecore = {
    description = "Pixiecore netboot server";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      ExecStart = "${pkgs.pixiecore}/bin/pixiecore boot ${kernel} ${initrd} --cmdline '${cmdline}' --debug --dhcp-no-bind --port 64172 --status-port 64172";
      AmbientCapabilities = [
        "CAP_NET_RAW"
        "CAP_NET_BIND_SERVICE"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_RAW"
        "CAP_NET_BIND_SERVICE"
      ];
      NoNewPrivileges = true;
    };
  };
}
