_: {
  virtualisation.oci-containers.containers.cloudflare-error-page = {
    image = "ghcr.io/fa0311/cloudflare-error-page-docker@sha256:501ef8c3c6d4a2836b9a1a77f967fb0fc455b3d6711f47290bcd5d3982b1647f";
    labels = {
      "traefik.enable" = "true";
      "traefik.http.services.cloudflare-error-page.loadbalancer.server.port" = "5000";
    };
  };
}
