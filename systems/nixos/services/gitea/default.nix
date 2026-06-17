{ config, ... }:

let
  domain = "git.yutakobayashi.com";
  sshDomain = "git-ssh.yutakobayashi.com";
in
{
  services.gitea = {
    enable = true;
    settings = {
      actions = {
        ENABLED = true;
      };
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
        SSH_DOMAIN = sshDomain;
      };
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;
      };
      session = {
        COOKIE_SECURE = true;
      };
    };
  };

  services.gitea-actions-runner.instances.B450M-Pro4 = {
    enable = true;
    name = "B450M-Pro4";
    url = "https://${domain}";
    tokenFile = config.sops.secrets.gitea-actions-runner-token.path;
    labels = [
      "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-latest"
      "ubuntu-22.04:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
    ];
  };

  sops.secrets.gitea-actions-runner-token = {
    sopsFile = ./secrets.yaml;
  };

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "http://localhost:3000";
  };

  my.services.cloudflared-tunnel.ingress.${sshDomain} = {
    service = "ssh://localhost:${toString config.services.forgejo.settings.server.SSH_PORT}";
  };
}
