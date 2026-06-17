{
  config,
  pkgs,
  inputs,
  ...
}:

let
  domain = "git.yutakobayashi.com";
in
{
  services.gitea-actions-runner.instances.default = {
    enable = true;
    name = config.networking.hostName;
    url = "https://${domain}";
    tokenFile = config.sops.secrets.gitea-actions-runner-token.path;
    labels = [
      "ubuntu-24.04:docker://docker.io/gitea/runner-images:ubuntu-24.04"
      "nix:host"
    ];
    hostPackages = with pkgs; [
      bash
      busybox
      curl
      git
      nodejs
      nix
      inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.niks3
    ];
  };

  sops.secrets.gitea-actions-runner-token = {
    sopsFile = ./secrets.yaml;
  };

  virtualisation.docker.enable = true;

  virtualisation.containers.containersConf.settings = {
    containers.dns_servers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
