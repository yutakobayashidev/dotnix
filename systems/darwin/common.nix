{
  inputs,
  lib,
  username,
  ...
}:

{
  imports = [
    ../common.nix
    ../shared/comin/alloy.nix
    ../../modules/darwin
    inputs.comin.darwinModules.comin
    inputs.sops-nix.darwinModules.sops
    ../../modules/profiles/darwin/base.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "/Users/${username}/.config/sops/age/keys.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/yutakobayashidev/dotnix";
      }
    ];
  };

  services.prometheus.exporters.node.enable = true;
  users.users._prometheus-node-exporter.home = lib.mkForce "/private/var/lib/prometheus-node-exporter";

  users.users.${username}.home = "/Users/${username}";

  nix = {
    settings = {
      trusted-users = [
        "root"
        username
      ];
      always-allow-substitutes = true;
    };
    gc.interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
  };

  system = {
    primaryUser = username;
    stateVersion = 6;
    startup.chime = false;
  };

  my.services = {
    caffeinate = {
      enable = true;
      preventSleepOnCharge = true;
    };
    newsyslog.enable = true;
    spotlight.enableIndex = true;
  };
}
