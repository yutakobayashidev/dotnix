_: {
  flake.modules.nixos.tempo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.services.tempo.enable = lib.mkEnableOption "Tempo for coding-agent traces";
      config = lib.mkIf config.my.services.tempo.enable {
        services.tempo = {
          enable = true;
          # Only the local collector ingests traces; clients use its existing
          # tailnet OTLP endpoint. All Tempo 3.x write paths stay in StateDirectory.
          settings = {
            server = {
              http_listen_address = "127.0.0.1";
              http_listen_port = 3200;
              grpc_listen_address = "127.0.0.1";
              grpc_listen_port = 9096;
            };
            distributor.receivers.otlp.protocols.grpc.endpoint = "127.0.0.1:4317";
            storage.trace = {
              backend = "local";
              local.path = "/var/lib/tempo/blocks";
              wal.path = "/var/lib/tempo/wal";
            };
            live_store = {
              wal.path = "/var/lib/tempo/live-store/traces";
              shutdown_marker_dir = "/var/lib/tempo/live-store/shutdown-marker";
            };
            backend_scheduler.local_work_path = "/var/lib/tempo/scheduler";
            overrides.defaults.compaction.block_retention = "720h";
          };
        };
        system.checks = [
          (pkgs.runCommand "tempo-config-check" { } ''
            ${lib.getExe' pkgs.tempo "tempo"} \
              -config.file=${(pkgs.formats.json { }).generate "tempo.json" config.services.tempo.settings} \
              -config.verify=true
            touch $out
          '')
        ];
        services.grafana.provision.datasources.settings.datasources = [
          {
            name = "Tempo";
            uid = "tempo";
            type = "tempo";
            url = "http://127.0.0.1:3200";
            jsonData.tracesToLogsV2 = {
              datasourceUid = "loki";
              spanStartTimeShift = "-5m";
              spanEndTimeShift = "5m";
              filterByTraceID = true;
            };
          }
        ];
      };
    };
}
