{ config, pkgs, ... }:

let
  otlpHttpPort = 4318;
  prometheusPort = 9464;
in
{
  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.opentelemetry-collector-contrib;
    settings = {
      receivers.otlp.protocols.http.endpoint = "0.0.0.0:${toString otlpHttpPort}";

      processors = {
        "attributes/pii_scrub".actions = [
          {
            key = "user.prompt";
            action = "delete";
          }
          {
            key = "tool.input.raw";
            action = "delete";
          }
        ];
        batch = { };
      };

      exporters = {
        prometheus = {
          endpoint = "127.0.0.1:${toString prometheusPort}";
          resource_to_telemetry_conversion.enabled = true;
        };
        "otlphttp/loki".endpoint =
          "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/otlp";
      };

      service.pipelines = {
        metrics = {
          receivers = [ "otlp" ];
          processors = [ "batch" ];
          exporters = [ "prometheus" ];
        };
        logs = {
          receivers = [ "otlp" ];
          processors = [
            "attributes/pii_scrub"
            "batch"
          ];
          exporters = [ "otlphttp/loki" ];
        };
      };
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "otel-collector";
      static_configs = [
        { targets = [ "127.0.0.1:${toString prometheusPort}" ]; }
      ];
    }
  ];

}
