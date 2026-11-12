{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "git.yutakobayashi.com";
  sshDomain = "git-ssh.yutakobayashi.com";
in
{
  services.gitea = {
    enable = true;
    lfs.enable = true;
    mailerPasswordFile = config.sops.secrets.cloudflare-email-sending-token.path;
    settings = {
      actions = {
        ENABLED = true;
      };
      oauth2_client = {
        ENABLE_AUTO_REGISTRATION = false;
        ACCOUNT_LINKING = "login";
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
        ROOT_URL = "https://${domain}/";
        SSH_DOMAIN = sshDomain;
      };
      service = {
        DISABLE_REGISTRATION = true;
        ENABLE_NOTIFY_MAIL = true;
        REQUIRE_SIGNIN_VIEW = false;
      };
      session = {
        COOKIE_SECURE = true;
      };
    };
  };

  # OIDC discovery needs working DNS and the local identity provider.
  systemd.services.gitea = {
    after = [
      "network-online.target"
      "pocket-id.service"
    ];
    wants = [
      "network-online.target"
      "pocket-id.service"
    ];
    serviceConfig.RestartSec = "30s";
  };

  # Authentication sources live in the database, so reconcile this source after
  # the upstream preStart has prepared app.ini and migrated the database.
  systemd.services.gitea.preStart = lib.mkAfter ''
    source_id=$(${lib.getExe config.services.gitea.package} admin auth list \
      | ${lib.getExe pkgs.gawk} '$2 == "pocket-id" { print $1 }')
    action=(add-oauth)
    if [ -n "$source_id" ]; then
      action=(update-oauth --id "$source_id")
    fi
    ${lib.getExe config.services.gitea.package} admin auth "''${action[@]}" \
      --name pocket-id --provider openidConnect --key gitea \
      --secret "$(cat ${config.sops.secrets.oidc-gitea-client-secret.path})" \
      --auto-discover-url https://id.yutakobayashi.com/.well-known/openid-configuration \
      --scopes openid --scopes profile --scopes email
  '';

  sops.secrets.oidc-gitea-client-secret = {
    owner = config.services.gitea.user;
    restartUnits = [ "gitea.service" ];
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
