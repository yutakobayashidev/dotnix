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
    ../services/navidrome
    ../services/immich
    ../services/gitea
    ../services/home-assistant
    ../services/grafana
    ../services/prometheus
    ../services/rsshub
    ../services/loki
    ../services/opentelemetry-collector
    ../services/oura-metrics
    ../services/archivebox
    ../services/n8n
    ../services/niks3
    ../services/comin
    ../services/comin/prometheus.nix
    ../services/cloudflare-error-page
    ../services/traefik
    ../services/atuin
    ../services/couchdb
    ../services/coredns
    ../services/twitter-bookmark-snap
    ../services/s3s
    ../services/headroom
    ../services/aivisspeech
    ../services/starla
    ../services/uptime-kuma
    ../services/netboot
    ../services/continuwuity
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disko.nix
    ./impermanence.nix
    inputs.nur-packages.nixosModules.px4_drv
    ../../../modules/profiles/nixos/base.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  ext.security.secureboot.enable = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelPackages = pkgs.linuxPackages_7_0;
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
    nameservers = lib.mkForce [ "127.0.0.1" ];
    wireless = {
      enable = true;
      secretsFile = config.sops.secrets.wifi.path;
      networks."TP-Link_42B4_5G".pskRaw = "ext:home";
    };
  };

  sops.secrets.wifi = {
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
  };

  fileSystems."/srv/bulk" = {
    device = "/dev/disk/by-label/bulk";
    fsType = "btrfs";
    options = [
      "subvol=@bulk"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/var/lib/immich" = {
    device = "/dev/disk/by-label/bulk";
    fsType = "btrfs";
    options = [
      "subvol=@bulk/immich"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/var/lib/immich-net-pics" = {
    device = "/dev/disk/by-label/bulk";
    fsType = "btrfs";
    options = [
      "subvol=@bulk/immich-net-pics"
      "compress=zstd:1"
      "noatime"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/immich-net-pics 0755 yuta users - -"
  ];

  fileSystems."/var/lib/nextcloud" = {
    device = "/dev/disk/by-label/bulk";
    fsType = "btrfs";
    options = [
      "subvol=@bulk/nextcloud"
      "compress=zstd:1"
      "noatime"
    ];
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.px4_drv.enable = true;

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
        port = 8081;
      }
    ];
  };

  boot.kernelModules = [
    "nvidia-uvm"
    "rtw88_8821au"
  ];

  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.docker.enable = true;

  services.cloudflared.enable = true;

  my.services.cloudflared-tunnel = {
    enable = true;
    id = "3e1ff621-e8bf-47d1-b095-4b5c15eec63c";
    credentialsFile = config.sops.secrets.cloudflared-tunnel.path;
  };

  sops.secrets.cloudflared-tunnel = {
    sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "25.11";
}
