{ config, ... }:

let
  domain = "git.yutakobayashi.com";
  sshDomain = "git-ssh.yutakobayashi.com";
in
{
  services.gitea = {
    enable = true;
    mailerPasswordFile = config.sops.secrets.cloudflare-email-sending-token.path;
    settings = {
      actions = {
        ENABLED = true;
      };
      mailer = {
        ENABLED = true;
        FROM = "Gitea <noreply@yutakobayashi.com>";
        PROTOCOL = "smtps";
        SMTP_ADDR = "smtp.mx.cloudflare.net";
        SMTP_PORT = 465;
        USER = "api_token";
      };
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
        SSH_DOMAIN = sshDomain;
      };
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };
      session = {
        COOKIE_SECURE = true;
      };
    };
  };

  sops.secrets.cloudflare-email-sending-token = {
    sopsFile = ./secrets.yaml;
    owner = config.services.gitea.user;
    restartUnits = [ "gitea.service" ];
  };

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "http://localhost:3000";
  };

  my.services.cloudflared-tunnel.ingress.${sshDomain} = {
    service = "ssh://localhost:${toString config.services.gitea.settings.server.SSH_PORT}";
  };
}
