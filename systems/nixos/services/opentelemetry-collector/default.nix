{
  config,
  lib,
  pkgs,
  ...
}:

let
  otlpHttpPort = 4318;
  # Remove known prompt and tool-content attributes at the shared collector.
  privateAttributes = [
    "user.prompt"
    "prompt"
    "tool.input.raw"
    "tool_input"
    "tool_parameters"
    "tool_arguments"
    "arguments"
    "output"
    "tool.output"
    "full_command"
    "command"
    "bash_command"
    "gen_ai.input.messages"
    "gen_ai.output.messages"
  ];
  scrubStatements =
    context: map (key: ''delete_key(${context}.attributes, "${key}")'') privateAttributes;
in
{
  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.opentelemetry-collector-contrib;
    settings = {
      receivers.otlp.protocols.http.endpoint = "0.0.0.0:${toString otlpHttpPort}";
      processors = {
        memory_limiter = {
          check_interval = "1s";
          limit_mib = 512;
          spike_limit_mib = 128;
        };
        "transform/pii_scrub" = {
          log_statements = [
            {
              context = "log";
              statements = scrubStatements "log";
            }
          ];
          trace_statements = [
            {
              context = "span";
              statements = scrubStatements "span";
            }
            {
              context = "spanevent";
              statements = scrubStatements "spanevent";
            }
          ];
        };
        # Codex/Claude versions can differ in metric temporality. Remote write
        # requires cumulative counters and histograms; pass cumulative through.
        deltatocumulative = { };
        batch = { };
      };
      exporters = {
        prometheus_remote_write = {
          endpoint = "http://127.0.0.1:8428/api/v1/write";
          translation_strategy = "UnderscoreEscapingWithoutSuffixes";
          resource_to_telemetry_conversion.enabled = true;
          max_batch_request_parallelism = 1;
        };
        "otlphttp/loki".endpoint =
          "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/otlp";
      }
      // lib.optionalAttrs config.my.services.tempo.enable {
        "otlp/tempo" = {
          endpoint = "127.0.0.1:4317";
          tls.insecure = true;
        };
      };
      service.pipelines = {
        metrics = {
          receivers = [ "otlp" ];
          processors = [
            "memory_limiter"
            "deltatocumulative"
            "batch"
          ];
          exporters = [ "prometheus_remote_write" ];
        };
        logs = {
          receivers = [ "otlp" ];
          processors = [
            "memory_limiter"
            "transform/pii_scrub"
            "batch"
          ];
          exporters = [ "otlphttp/loki" ];
        };
      }
      // lib.optionalAttrs config.my.services.tempo.enable {
        traces = {
          receivers = [ "otlp" ];
          processors = [
            "memory_limiter"
            "transform/pii_scrub"
            "batch"
          ];
          exporters = [ "otlp/tempo" ];
        };
      };
    };
  };

  system.checks = [
    (pkgs.runCommand "coding-agent-otel-config-check" { } ''
      ${lib.getExe config.services.opentelemetry-collector.package} validate \
        --config=${
          (pkgs.formats.json { }).generate "otel-config.json" config.services.opentelemetry-collector.settings
        }
      touch $out
    '')
  ];

}
