{
  config,
  lib,
  pkgs,
  ...
}:
let
  aivisspeechPort = 10101;
  domain = "aivisspeech.home.yutakobayashi.com";
in
{
  virtualisation.oci-containers.containers.aivisspeech = {
    image = "ghcr.io/aivis-project/aivisspeech-engine:nvidia-latest@sha256:581c9d0881c0642c3b5a0a323ccb138b11ca92d04009d4d90fbf2877ebc29e70";
    hostname = "aivisspeech";
    autoRemoveOnStop = false;
    ports = [ "127.0.0.1:${toString aivisspeechPort}:10101" ];
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
    "d /srv/bulk/aivisspeech/engine 0755 root root -"
  ];

  services.traefik.dynamicConfigOptions.http = {
    routers.aivisspeech = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "aivisspeech";
      tls.certResolver = "letsencrypt";
    };
    services.aivisspeech.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString aivisspeechPort}"; }
    ];
  };
}
