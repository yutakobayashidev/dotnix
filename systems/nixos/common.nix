{
  inputs,
  pkgs,
  username,
  lib,
  ...
}:

{
  # Base modules shared by regular NixOS hosts. Host-specific profiles still
  # decide whether the machine is desktop, server, or WSL.
  imports = [
    ../common.nix
    inputs.comin.nixosModules.comin
    inputs.sops-nix.nixosModules.sops
    inputs.nix-topology.nixosModules.default
    ../../modules/nixos
  ];

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "/home/${username}/.config/sops/age/keys.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };

  nix.gc.dates = "weekly";

  nix.settings = {
    keep-outputs = true;
    keep-derivations = true;
    connect-timeout = 5;
    allowed-users = [ username ];
    trusted-users = [
      "root"
      username
    ];
  };

  # dhcpcd tries to manage Docker's veth interfaces and crashes (SEGV in ipv6nd_expire)
  # in a loop, which eventually causes DHCP lease renewal to fail after a few days
  networking.dhcpcd.denyInterfaces = [ "veth*" ];

  virtualisation.docker.enable = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    # fix DNS issue caused by systemd-resolved
    # https://discourse.nixos.org/t/rootless-docker-systemd-resolved-and-dns-inside-containers/47030
    daemon.settings = {
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };

  time.timeZone = "Asia/Tokyo";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "adbusers"
    ];
    hashedPassword = "$6$jDoJHXil35EgTukO$t3Y3A9E37.q1MB7DTnud3YG8gpXS.QtXozfM95nG882i6slkmYHEtWrvdRK1iNiTrM2R.xzhbljbM31Uzc4XN1";
  };

  users.mutableUsers = false;

  programs.zsh.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
    ];
  };

  programs.ssh.startAgent = true;

  services.openssh.enable = true;
  services.pcscd.enable = true;
  my.services.kubo.enable = true;

  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';
}
