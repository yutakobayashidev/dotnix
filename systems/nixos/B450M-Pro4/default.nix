{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../common.nix
    ../services/nextcloud
    ../services/immich
    ../services/gitea
    ../services/home-assistant
    ../services/grafana
    ../services/prometheus
    ../services/loki
    ../services/opentelemetry-collector
    ../services/oura-metrics
    ../services/archivebox
    ../services/comin
    ../services/comin/prometheus.nix
    ../services/cloudflare-error-page
    ../services/traefik
    ../services/atuin
    ../services/coredns
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disko.nix
    ./impermanence.nix
    inputs.nur-packages.nixosModules.px4_drv
    inputs.nur-packages.nixosModules.rtl8812au
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/cryptroot";
    allowDiscards = true;
    bypassWorkqueues = true;
  };
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "ahci"
  ];

  networking = {
    hostName = "B450M-Pro4";
    useDHCP = lib.mkDefault true;
    useNetworkd = true;
    wireless = {
      enable = true;
      secretsFile = config.sops.secrets.wifi.path;
      networks."TP-Link_42B4_5G".pskRaw = "ext:home";
    };
  };

  sops.secrets.wifi = { };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.px4_drv.enable = true;
  hardware.rtl8812au.enable = true;

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      config.boot.kernelPackages.nvidiaPackages.stable
    ];
  };

  services.nginx.virtualHosts."localhost" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 8080;
      }
    ];
  };

  boot.kernelModules = [ "nvidia-uvm" ];

  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;

  system.stateVersion = "25.11";
}
