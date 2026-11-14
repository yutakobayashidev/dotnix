{
  services.unifi = {
    enable = true;
    maximumJavaHeapSize = 1024;
  };

  # vmalert already uses 8880 on this host.
  systemd.services.unifi.preStart = ''
    mkdir -p /var/lib/unifi/data
    touch /var/lib/unifi/data/system.properties
    sed -i '/^[[:space:]]*portal\.http\.port[[:space:]]*=/d' /var/lib/unifi/data/system.properties
    echo 'portal.http.port=18880' >> /var/lib/unifi/data/system.properties
  '';

  networking.firewall = {
    allowedTCPPorts = [ 8080 18880 8843 6789 ];
    allowedUDPPorts = [ 3478 10001 ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.unifi = {
      entryPoints = [ "websecure" ];
      rule = "Host(`unifi.home.yutakobayashi.com`)";
      service = "unifi";
      tls.certResolver = "letsencrypt";
    };
    services.unifi.loadBalancer = {
      servers = [ { url = "https://127.0.0.1:8443"; } ];
      serversTransport = "unifi";
    };
    # The controller generates its own certificate; TLS terminates at Traefik.
    serversTransports.unifi.insecureSkipVerify = true;
  };
}
