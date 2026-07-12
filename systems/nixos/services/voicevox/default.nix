_:
let
  domain = "voicevox.home.yutakobayashi.com";
in
{
  virtualisation.oci-containers.containers.voicevox = {
    image = "voicevox/voicevox_engine:nvidia-0.25.1@sha256:9f0e765d447d692d1b9d3ca020551ebbe1fd979ec113aa8d72168b47e151648b";
    hostname = "voicevox";
    autoRemoveOnStop = false;
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.voicevox.rule" = "Host(`${domain}`)";
      "traefik.http.routers.voicevox.entrypoints" = "web,websecure";
      "traefik.http.routers.voicevox.tls.certResolver" = "letsencrypt";
      "traefik.http.services.voicevox.loadbalancer.server.port" = "50021";
    };
    extraOptions = [
      "--device=nvidia.com/gpu=all"
      "--memory=8g"
      "--restart=unless-stopped"
    ];
  };
}
