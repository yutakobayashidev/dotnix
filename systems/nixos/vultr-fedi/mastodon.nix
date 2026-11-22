{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "fedi.yutakobayashi.com";
  cfg = config.services.mastodon;
  mastodonSecret = {
    sopsFile = ./secrets.yaml;
    owner = cfg.user;
  };
  nginxSecret = {
    sopsFile = ./secrets.yaml;
    owner = config.services.nginx.user;
  };
in
{
  services = {
    mastodon = {
      enable = true;
      localDomain = domain;
      configureNginx = true;
      streamingProcesses = 1;

      # Carried over from the current server's .env.production.
      secretKeyBaseFile = config.sops.secrets."mastodon/secret-key-base".path;
      vapidPublicKeyFile = config.sops.secrets."mastodon/vapid-public-key".path;
      vapidPrivateKeyFile = config.sops.secrets."mastodon/vapid-private-key".path;
      activeRecordEncryptionDeterministicKeyFile =
        config.sops.secrets."mastodon/active-record-encryption-deterministic-key".path;
      activeRecordEncryptionKeyDerivationSaltFile =
        config.sops.secrets."mastodon/active-record-encryption-key-derivation-salt".path;
      activeRecordEncryptionPrimaryKeyFile =
        config.sops.secrets."mastodon/active-record-encryption-primary-key".path;

      # Cloudflare Email Service. The token is tofu-configuration's
      # `mastodon_email_sending_token` output.
      smtp = {
        createLocally = false;
        host = "smtp.mx.cloudflare.net";
        port = 465;
        authenticate = true;
        user = "api_token";
        passwordFile = config.sops.secrets."mastodon/smtp-password".path;
        fromAddress = "Mastodon <notifications@${domain}>";
      };

      extraConfig = {
        # Cloudflare accepts only implicit TLS on port 465.
        SMTP_TLS = "true";
        # Media stays in the existing R2 bucket. S3_ENDPOINT and the access keys
        # live in the env file below because the endpoint contains the account ID.
        S3_ENABLED = "true";
        S3_BUCKET = "fediverse";
        S3_ALIAS_HOST = "fedi-files.yutakobayashi.com";
        S3_PROTOCOL = "https";
        S3_PERMISSION = "private";
      };
      extraEnvFiles = [ config.sops.secrets."mastodon/s3-env".path ];

      mediaAutoRemove = {
        enable = true;
        olderThanDays = 14;
      };
    };

    # The current server runs PostgreSQL 18; keep the major version so that its
    # dump restores without a downgrade.
    postgresql.package = pkgs.postgresql_18;

    postgresqlBackup = {
      enable = true;
      databases = [ cfg.database.name ];
      compression = "zstd";
    };

    # TLS terminates at Cloudflare. The tunnel reaches nginx over HTTPS with a
    # Cloudflare Origin CA certificate: the module's proxy headers send
    # X-Forwarded-Proto as $scheme, so plain HTTP would make Mastodon redirect
    # to HTTPS forever.
    nginx.virtualHosts.${domain} = {
      enableACME = false;
      sslCertificate = config.sops.secrets."cloudflare-origin/certificate".path;
      sslCertificateKey = config.sops.secrets."cloudflare-origin/private-key".path;
    };
  };

  # mediaAutoRemove removes attachments and preview cards only; remote avatars and
  # headers keep growing without this.
  systemd.services.mastodon-media-auto-remove.script = lib.mkAfter ''
    ${cfg.package}/bin/tootctl media remove --prune-profiles --days=${toString cfg.mediaAutoRemove.olderThanDays}
  '';

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "https://localhost";
    originRequest.originServerName = domain;
  };

  sops.secrets = {
    "mastodon/secret-key-base" = mastodonSecret;
    "mastodon/vapid-public-key" = mastodonSecret;
    "mastodon/vapid-private-key" = mastodonSecret;
    "mastodon/active-record-encryption-deterministic-key" = mastodonSecret;
    "mastodon/active-record-encryption-key-derivation-salt" = mastodonSecret;
    "mastodon/active-record-encryption-primary-key" = mastodonSecret;
    "mastodon/smtp-password" = mastodonSecret;
    # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and S3_ENDPOINT for R2.
    "mastodon/s3-env" = mastodonSecret;
    "cloudflare-origin/certificate" = nginxSecret;
    "cloudflare-origin/private-key" = nginxSecret;
  };
}
