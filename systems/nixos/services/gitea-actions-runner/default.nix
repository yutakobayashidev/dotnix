{ config, ... }:

let
  domain = "git.yutakobayashi.com";
in
{
  services.gitea-actions-runner.instances.B450M-Pro4 = {
    enable = true;
    name = "B450M-Pro4";
    url = "https://${domain}";
    tokenFile = config.sops.secrets.gitea-actions-runner-token.path;
    labels = [
      "ubuntu-24.04:docker://ghcr.io/gitea/runner-images:ubuntu-24.04"
    ];
  };

  sops.secrets.gitea-actions-runner-token = {
    sopsFile = ./secrets.yaml;
  };
}
