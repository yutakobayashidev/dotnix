{ config, ... }:

let
  inherit (config.services.loki) dataDir;
in
{
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_port = 3100;
      };
      common = {
        path_prefix = dataDir;
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        ring.instance_addr = "127.0.0.1";
        storage.filesystem = {
          chunks_directory = "${dataDir}/chunks";
          rules_directory = "${dataDir}/rules";
        };
      };
      schema_config.configs = [
        {
          from = "2026-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "${dataDir}/tsdb-active";
          cache_location = "${dataDir}/tsdb-cache";
        };
        filesystem.directory = "${dataDir}/chunks";
      };
      compactor = {
        working_directory = "${dataDir}/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
      limits_config.retention_period = "720h";
      limits_config.otlp_config.resource_attributes.attributes_config = [
        {
          action = "index_label";
          attributes = [
            "account_name"
            "deployment.environment"
            "team"
            "role"
            "service.name"
          ];
        }
      ];
      analytics.reporting_enabled = false;
      ruler.enable_api = false;
    };
  };

}
