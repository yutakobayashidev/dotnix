{
  inputs,
  pkgs,
  username,
  ...
}:

{
  # Base modules shared by regular NixOS hosts. Host-specific profiles still
  # decide whether the machine is desktop, server, or WSL.
  imports = [
    ../common.nix
    inputs.comin.nixosModules.comin
    inputs.sops-nix.nixosModules.sops
    ../../nix/modules/nixos
  ];

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "/home/${username}/.config/sops/age/keys.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };

  my.services.tailscale.enable = true;

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

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
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

  environment.systemPackages = with pkgs; [
    coreutils
    dnsmasq
    dvb-apps
    opensc
    pcsc-tools
    pciutils
    tcpdump
    usbutils
    v4l-utils
  ];

  programs.zsh.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
    ];
  };

  services.openssh.enable = true;
  services.pcscd.enable = true;
  my.services.kubo.enable = true;

  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';
}
