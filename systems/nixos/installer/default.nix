{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  codex = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  installerHelp = pkgs.writeShellApplication {
    name = "installer-help";
    runtimeInputs = [ pkgs.iproute2 ];
    text = ''
      cat <<'EOF'

      === dotnix NixOS Installer ===

      Network:
        Wired: DHCP is automatic
        Wi-Fi: nmcli device wifi connect <SSID> --ask

      Remote access:
        1. Set a temporary root password: passwd
        2. Connect from another machine: ssh root@<IP>

      Install:
        git clone https://github.com/yutakobayashidev/dotnix.git
        cd dotnix
        Follow docs/systems/<host>.md

      IPv4 addresses:
      EOF
      ip -brief -4 address show scope global
      echo
    '';
  };
in
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  networking = {
    hostName = "nixos-installer";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  services = {
    getty.autologinUser = lib.mkForce "root";
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
        PermitEmptyPasswords = false;
      };
    };
    pcscd.enable = true;
  };

  users.users.root.initialHashedPassword = lib.mkForce "";

  environment.systemPackages = with pkgs; [
    age
    age-plugin-yubikey
    btrfs-progs
    codex
    coreutils
    cryptsetup
    curl
    disko
    dvb-apps
    efibootmgr
    git
    installerHelp
    jq
    mkpasswd
    opensc
    parted
    pciutils
    pcsc-tools
    psmisc
    rsync
    sbctl
    sops
    ssh-to-age
    tcpdump
    usbutils
    v4l-utils
    vim
    vulnix
    wget
    yubikey-manager
  ];

  systemd.services.installer-banner = {
    description = "Display installer help and IP addresses";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe installerHelp;
      StandardOutput = "tty";
      TTYPath = "/dev/tty1";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = config.system.nixos.release;
}
