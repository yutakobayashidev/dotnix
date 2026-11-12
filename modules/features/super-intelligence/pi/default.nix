_:

{
  flake.modules.homeManager."pi" =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      cfg = config.my.programs.pi;
    in
    {
      options.my.programs.pi = {
        enable = lib.mkEnableOption "Pi";
        telemetry.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Export Pi usage metrics without message or tool content.";
        };
        telemetry.endpoint = lib.mkOption {
          type = lib.types.str;
          default =
            if osConfig.my.services.agentTelemetry.enable or false then
              "http://127.0.0.1:${toString osConfig.my.services.agentTelemetry.httpPort}/v1/metrics"
            else
              "http://B450M-Pro4.tail29d068.ts.net:4318/v1/metrics";
          description = "OTLP HTTP metrics endpoint.";
        };
        acp.enable = lib.mkEnableOption "Pi ACP adapter";
      };

      config = lib.mkIf cfg.enable {
        home.file.".pi/agent/extensions/otel-metrics.ts" = lib.mkIf cfg.telemetry.enable {
          source = pkgs.replaceVars ./extensions/otel-metrics.ts {
            endpoint = cfg.telemetry.endpoint;
            hostname = osConfig.networking.hostName or "unknown";
          };
        };
        home.packages = [ pkgs.llm-agents.pi ] ++ lib.optional cfg.acp.enable pkgs.pi-acp;
      };
    };
}
