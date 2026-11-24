{ config, ... }:

# Self-hosted Octo STS: exchanges GitHub Actions OIDC tokens for short-lived
# yuta-octo-sts GitHub App tokens, as each repository's
# .github/chainguard/<identity>.sts.yaml trust policy allows. The App holds
# only Contents and Pull requests write, so a leaked key cannot change
# repository settings. See docs/octo-sts.md.
let
  domain = "sts.yutakobayashi.com";
  # Outside the 1879x range, which tunnel-client health endpoints use.
  port = 23792;
  appId = "5900527";
  # Container user of the ko-built image.
  imageUid = 65532;
in
{
  virtualisation.oci-containers.containers.octo-sts = {
    # v0.14.4, verified with cosign against octo-sts/app's container workflow.
    image = "ghcr.io/octo-sts/app@sha256:d679133fa8b824718f828290bdb1a6353c32989718cc31418a0bb783a20781d9";
    ports = [ "127.0.0.1:${toString port}:8080" ];
    volumes = [
      "${config.sops.secrets.octo-sts-app-key.path}:/run/secrets/app.pem:ro"
    ];
    environment = {
      PORT = "8080";
      STS_DOMAIN = domain;
      GITHUB_APP_IDS = appId;
      APP_SECRET_CERTIFICATE_FILE = "/run/secrets/app.pem";
      METRICS = "false";
      # The caller names the issuer before its token is verified; only
      # GitHub Actions may make this host fetch OIDC discovery documents,
      # and never from private addresses on the home network.
      OCTOSTS_ALLOWED_ISSUERS = "https://token.actions.githubusercontent.com";
      OCTOSTS_OIDC_BLOCK_PRIVATE_IPS = "true";
    };
  };

  sops.secrets.octo-sts-app-key = {
    sopsFile = ../../../../secrets/octo-sts.yaml;
    key = "github-app-private-key";
    uid = imageUid;
    mode = "0400";
    restartUnits = [ "podman-octo-sts.service" ];
  };

  my.services.cloudflared-tunnel.ingress.${domain} = {
    service = "http://localhost:${toString port}";
  };
}
