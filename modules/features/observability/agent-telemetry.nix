{ lib, ... }:
let
  module =
    { config, ... }:
    let
      cfg = config.my.services.agentTelemetry;
      server = cfg.mode == "server";
      hostname = config.networking.hostName;
      backend = if server then "127.0.0.1" else cfg.storageHost;
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
      localIdentity = builtins.toJSON [
        ''set(attributes["host"], "${hostname}")''
        ''set(attributes["host.name"], "${hostname}")''
      ];
      legacyIdentity = builtins.toJSON [
        ''set(attributes["host"], attributes["host.name"]) where attributes["host"] == nil and attributes["host.name"] != nil''
        ''set(attributes["host"], attributes["deployment.environment.name"]) where attributes["host"] == nil and attributes["deployment.environment.name"] != nil''
        ''set(attributes["host"], attributes["deployment.environment"]) where attributes["host"] == nil and attributes["deployment.environment"] != nil''
        ''replace_pattern(attributes["host"], "^home-", "") where attributes["host"] != nil''
        ''set(attributes["host"], "unknown") where attributes["host"] == nil''
      ];
      # Keep the old tailnet HTTP ingress for Ori and clients not yet restarted.
      # It must never inherit this collector's own hostname.
      pipeline = name: identity: local: ''
        otelcol.processor.memory_limiter "${name}" {
          check_interval = "1s"
          limit = "512MiB"
          spike_limit = "128MiB"
          output {
            metrics = [otelcol.processor.transform.${name}.input]
            logs = [otelcol.processor.transform.${name}.input]
            traces = [otelcol.processor.transform.${name}.input]
          }
        }
        otelcol.processor.transform "${name}" {
          error_mode = "ignore"
          metric_statements {
            context = "resource"
            statements = ${identity}
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
            statements = ${identity}
          }
          log_statements {
            context = "log"
            statements = ${scrub "log"}
          }
          trace_statements {
            context = "resource"
            statements = ${identity}
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
            metrics = [otelcol.processor.deltatocumulative.${name}.input]
            logs = [otelcol.exporter.otlphttp.agent_loki.input]
            traces = [otelcol.exporter.otlp.agent_tempo.input]
          }
        }
        otelcol.processor.deltatocumulative "${name}" {
          max_stale = "168h"
          output { metrics = [otelcol.exporter.prometheus.${name}.input] }
        }
        otelcol.exporter.prometheus "${name}" {
          add_metric_suffixes = false
          resource_to_telemetry_conversion = true
          forward_to = [prometheus.remote_write.${name}.receiver]
        }
        prometheus.remote_write "${name}" {
          ${lib.optionalString local ''external_labels = { host = "${hostname}" }''}
          endpoint { url = "http://${backend}:8428/api/v1/write" }
        }
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
            || (user.my.programs.dsh.enable or false)
          ) (lib.attrValues (config.home-manager.users or { }));
          description = "Collect coding-agent OTLP locally with Alloy.";
        };
        mode = lib.mkOption {
          type = lib.types.enum [
            "forward"
            "server"
          ];
          default = "forward";
          description = "Ship to storage over the tailnet, or use local storage and retain legacy OTLP ingress.";
        };
        storageHost = lib.mkOption {
          type = lib.types.str;
          default = "B450M-Pro4.tail29d068.ts.net";
          description = "Tailnet host for VictoriaMetrics, Loki and Tempo.";
        };
        httpPort = lib.mkOption {
          type = lib.types.port;
          default = if server then 4319 else 4318;
          description = "Loopback OTLP HTTP port; the server retains port 4318 for legacy remote clients.";
        };
      };
      config = lib.mkIf cfg.enable {
        my.services.alloy = {
          enable = true;
          stabilityLevel = "experimental";
          configs.agent-telemetry = ''
            otelcol.receiver.otlp "coding_agents" {
              grpc { endpoint = "127.0.0.1:4317" }
              http { endpoint = "127.0.0.1:${toString cfg.httpPort}" }
              output {
                metrics = [otelcol.processor.memory_limiter.coding_agents.input]
                logs = [otelcol.processor.memory_limiter.coding_agents.input]
                traces = [otelcol.processor.memory_limiter.coding_agents.input]
              }
            }
            ${pipeline "coding_agents" localIdentity true}
            otelcol.exporter.otlphttp "agent_loki" {
              client { endpoint = "http://${backend}:3100/otlp" }
            }
            otelcol.exporter.otlp "agent_tempo" {
              client {
                endpoint = "${backend}:14317"
                tls { insecure = true }
              }
            }
          ''
          + lib.optionalString server ''
            otelcol.receiver.otlp "legacy_agents" {
              http { endpoint = "0.0.0.0:4318" }
              output {
                metrics = [otelcol.processor.memory_limiter.legacy_agents.input]
                logs = [otelcol.processor.memory_limiter.legacy_agents.input]
                traces = [otelcol.processor.memory_limiter.legacy_agents.input]
              }
            }
            ${pipeline "legacy_agents" legacyIdentity false}
          '';
        };
      };
    };
in
{
  flake.modules.nixos.agent-telemetry = module;
  flake.modules.darwin.agent-telemetry = module;
}
