# Adapted from natsukium/dotfiles' local OTLP pipeline. Keep one tailnet
# gateway so existing clients and Ori do not need direct access to storage APIs.
{ lib, ... }:
let
  module =
    { config, ... }:
    let
      cfg = config.my.services.agentTelemetry;
      server = cfg.mode == "server";
      hostname = config.networking.hostName;
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
      scrub =
        context:
        builtins.toJSON (map (key: ''delete_key(${context}.attributes, "${key}")'') privateAttributes);
      resourceStatements = builtins.toJSON (
        if server then
          [
            ''set(attributes["host"], attributes["host.name"]) where attributes["host"] == nil and attributes["host.name"] != nil''
            ''set(attributes["host"], attributes["deployment.environment"]) where attributes["host"] == nil and attributes["deployment.environment"] != nil''
            ''replace_pattern(attributes["host"], "^home-", "") where attributes["host"] != nil''
            ''set(attributes["host"], "unknown") where attributes["host"] == nil''
          ]
        else
          [
            ''set(attributes["host"], "${hostname}")''
            ''set(attributes["host.name"], "${hostname}") where attributes["host.name"] == nil''
          ]
      );
      output =
        if server then
          ''
            metrics = [otelcol.processor.deltatocumulative.coding_agents.input]
            logs = [otelcol.exporter.otlphttp.agent_loki.input]
            traces = [otelcol.exporter.otlp.agent_tempo.input]
          ''
        else
          ''
            metrics = [otelcol.exporter.otlphttp.agent_gateway.input]
            logs = [otelcol.exporter.otlphttp.agent_gateway.input]
            traces = [otelcol.exporter.otlphttp.agent_gateway.input]
          '';
    in
    {
      options.my.services.agentTelemetry = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = lib.any (
            user:
            (user.my.programs.codex.enable or false)
            || (user.my.programs.claude-code.enable or false)
            || (user.my.programs.pi.enable or false)
          ) (lib.attrValues (config.home-manager.users or { }));
          description = "Collect coding-agent OTLP locally with Alloy.";
        };
        mode = lib.mkOption {
          type = lib.types.enum [
            "forward"
            "server"
          ];
          default = "forward";
          description = "Forward to the tailnet gateway, or store all three signals locally.";
        };
        endpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://B450M-Pro4.tail29d068.ts.net:4318";
          description = "Tailnet OTLP HTTP gateway used by forwarding collectors.";
        };
      };
      config = lib.mkIf cfg.enable {
        my.services.alloy = {
          enable = true;
          stabilityLevel = "experimental";
          configs.agent-telemetry = ''
            otelcol.receiver.otlp "coding_agents" {
              http { endpoint = "${if server then "0.0.0.0" else "127.0.0.1"}:4318" }
              output {
                metrics = [otelcol.processor.memory_limiter.coding_agents.input]
                logs = [otelcol.processor.memory_limiter.coding_agents.input]
                traces = [otelcol.processor.memory_limiter.coding_agents.input]
              }
            }
            otelcol.processor.memory_limiter "coding_agents" {
              check_interval = "1s"
              limit = "512MiB"
              spike_limit = "128MiB"
              output {
                metrics = [otelcol.processor.transform.coding_agents.input]
                logs = [otelcol.processor.transform.coding_agents.input]
                traces = [otelcol.processor.transform.coding_agents.input]
              }
            }
            otelcol.processor.transform "coding_agents" {
              error_mode = "ignore"
              metric_statements {
                context = "resource"
                statements = ${resourceStatements}
              }
              metric_statements {
                context = "datapoint"
                statements = [
                  `delete_key(attributes, "turn.id") where IsMatch(metric.name, "^codex[.]")`,
                  `delete_key(attributes, "conversation.id") where IsMatch(metric.name, "^codex[.]")`,
                ]
              }
              log_statements {
                context = "resource"
                statements = ${resourceStatements}
              }
              log_statements {
                context = "log"
                statements = ${scrub "log"}
              }
              trace_statements {
                context = "resource"
                statements = ${resourceStatements}
              }
              trace_statements {
                context = "span"
                statements = ${scrub "span"}
              }
              trace_statements {
                context = "spanevent"
                statements = ${scrub "spanevent"}
              }
              output {
                ${output}
              }
            }
          ''
          + (
            if server then
              ''
                otelcol.processor.deltatocumulative "coding_agents" {
                  max_stale = "168h"
                  output { metrics = [otelcol.exporter.prometheus.coding_agents.input] }
                }
                otelcol.exporter.prometheus "coding_agents" {
                  add_metric_suffixes = false
                  resource_to_telemetry_conversion = true
                  forward_to = [prometheus.remote_write.coding_agents.receiver]
                }
                prometheus.remote_write "coding_agents" {
                  endpoint { url = "http://127.0.0.1:8428/api/v1/write" }
                }
                otelcol.exporter.otlphttp "agent_loki" {
                  client { endpoint = "http://127.0.0.1:3100/otlp" }
                }
                otelcol.exporter.otlp "agent_tempo" {
                  client {
                    endpoint = "127.0.0.1:4317"
                    tls { insecure = true }
                  }
                }
              ''
            else
              ''
                otelcol.exporter.otlphttp "agent_gateway" {
                  client { endpoint = "${cfg.endpoint}" }
                  retry_on_failure { max_elapsed_time = "0s" }
                  sending_queue { queue_size = 10000 }
                }
              ''
          );
        };
      };
    };
in
{
  flake.modules.nixos.agent-telemetry = module;
  flake.modules.darwin.agent-telemetry = module;
}
