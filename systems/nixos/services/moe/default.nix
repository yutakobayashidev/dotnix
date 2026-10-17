{
  config,
  lib,
  pkgs,
  ...
}:
let
  stateDir = "/srv/bulk/moe";
  network = "moe";
  names = [
    "moe-server"
    "moe-machine-learning"
    "moe-redis"
    "moe-database"
  ];
  container = alias: {
    environment.TZ = "Asia/Tokyo";
    networks = [ network ];
    extraOptions = [ "--network-alias=${alias}" ];
  };
in
{
  assertions = [
    {
      assertion = config.virtualisation.oci-containers.backend == "podman";
      message = "moe uses the host's Podman OCI backend.";
    }
  ];

  virtualisation.oci-containers.containers = {
    moe-server = lib.recursiveUpdate (container "immich-server") {
      image = "ghcr.io/immich-app/immich-server:v3.3.3@sha256:bae7664ff3aa4c2c1fcbdcdd86b40b105643c5f861f3e6a770fc760089f25862";
      ports = [ "127.0.0.1:2284:2283" ];
      dependsOn = [
        "moe-database"
        "moe-redis"
      ];
      environment = {
        DB_HOSTNAME = "database";
        DB_USERNAME = "postgres";
        DB_DATABASE_NAME = "immich";
        REDIS_HOSTNAME = "redis";
      };
      environmentFiles = [ "${stateDir}/database.env" ];
      volumes = [
        "${stateDir}/library:/data"
        "/var/lib/immich-net-pics:/external/net-pics:ro"
      ];
    };
    moe-machine-learning = (container "immich-machine-learning") // {
      image = "ghcr.io/immich-app/immich-machine-learning:v3.3.3@sha256:73915f07e1f4289ba45b174c58443db74cef47ddf502613f475fc5e52458ea42";
      volumes = [ "${stateDir}/model-cache:/cache" ];
    };
    moe-redis = (container "redis") // {
      image = "docker.io/valkey/valkey:9@sha256:c123e3715db63d06d4ad6964884037aa0d5d4d703939b9929954112889708e1d";
      volumes = [ "${stateDir}/redis:/data" ];
    };
    moe-database = lib.recursiveUpdate (container "database") {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
        DB_STORAGE_TYPE = "HDD";
      };
      environmentFiles = [ "${stateDir}/database.env" ];
      volumes = [ "${stateDir}/postgres:/var/lib/postgresql/data" ];
      extraOptions = [
        "--network-alias=database"
        "--shm-size=128m"
      ];
    };
  };

  systemd.services = {
    moe-setup = {
      description = "Prepare HDD storage and network for moe Immich";
      unitConfig.RequiresMountsFor = [ "/srv/bulk" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
      };
      script = ''
        install -d -m 0700 ${stateDir}
        install -d -m 0755 ${stateDir}/{library,model-cache,redis}
        install -d -m 0700 ${stateDir}/postgres
        if [ ! -e ${stateDir}/database.env ]; then
          password=$(${lib.getExe pkgs.openssl} rand -hex 32)
          printf 'DB_PASSWORD=%s\nPOSTGRES_PASSWORD=%s\n' "$password" "$password" > ${stateDir}/database.env
        fi
        if ! ${lib.getExe pkgs.podman} network exists ${network}; then
          ${lib.getExe pkgs.podman} network create ${network}
        fi
      '';
    };
  }
  // lib.genAttrs (map (name: "podman-${name}") names) (name: {
    requires = [ "moe-setup.service" ];
    after = [ "moe-setup.service" ];
    serviceConfig.RestartSec = "5s";
    unitConfig.RequiresMountsFor = [
      "/srv/bulk"
    ]
    ++ lib.optional (name == "podman-moe-server") "/var/lib/immich-net-pics";
  });

  services.traefik.dynamicConfigOptions.http = {
    routers.moe = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`moe.home.yutakobayashi.com`)";
      service = "moe";
      tls.certResolver = "letsencrypt";
    };
    services.moe.loadBalancer.servers = [ { url = "http://127.0.0.1:2284"; } ];
  };
}
