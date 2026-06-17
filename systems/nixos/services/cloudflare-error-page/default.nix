{ ... }:
{
  virtualisation.oci-containers.containers.cloudflare-error-page = {
    image = "ghcr.io/fa0311/cloudflare-error-page-docker:latest";
    labels = {
      "traefik.enable" = "true";
      "traefik.http.services.cloudflare-error-page.loadbalancer.server.port" = "5000";
    };
  };
}
