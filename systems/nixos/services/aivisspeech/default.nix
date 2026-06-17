{ ... }:
let
  domain = "aivisspeech.home.yutakobayashi.com";
in
{
  virtualisation.oci-containers.containers.aivisspeech = {
    image = "ghcr.io/aivis-project/aivisspeech-engine:nvidia-latest@sha256:581c9d0881c0642c3b5a0a323ccb138b11ca92d04009d4d90fbf2877ebc29e70";
    hostname = "aivisspeech";
    autoRemoveOnStop = false;
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.aivisspeech.rule" = "Host(`${domain}`)";
      "traefik.http.routers.aivisspeech.entrypoints" = "web,websecure";
      "traefik.http.routers.aivisspeech.tls.certResolver" = "letsencrypt";
      "traefik.http.services.aivisspeech.loadbalancer.server.port" = "10101";
    };
    volumes = [
      "/srv/bulk/aivisspeech/engine:/home/user/.local/share/AivisSpeech-Engine-Dev"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=all"
      "--memory=8g"
      "--restart=unless-stopped"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/bulk/aivisspeech/engine 0777 root root -"
  ];
}
