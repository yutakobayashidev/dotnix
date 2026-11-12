_:

{
  flake.modules.homeManager."dsh" =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      cfg = config.my.programs.dsh;
      telemetryPatch = (pkgs.formats.yaml { }).generate "dsh-metrics.yml" [
        {
          insert = [
            {
              id = "dotnix-otel-metrics";
              name = "file://${./otel-metrics.mjs}";
              config.endpoint = cfg.telemetry.endpoint;
            }
          ];
        }
      ];
      launcher = pkgs.writeShellScript "dsh-with-metrics" (
        lib.replaceStrings
          [ "@dsh@" "@patch@" ]
          [ "${pkgs.llm-agents.dsh}/bin/dsh" (toString telemetryPatch) ]
          (builtins.readFile ./launcher.sh)
      );
      package =
        if cfg.telemetry.enable then
          pkgs.symlinkJoin {
            name = "dsh-with-metrics";
            paths = [ pkgs.llm-agents.dsh ];
            postBuild = ''
              rm $out/bin/dsh
              ln -s ${launcher} $out/bin/dsh
            '';
          }
        else
          pkgs.llm-agents.dsh;
      autoAuth = import ./auto-auth.nix { inherit config lib pkgs; };
      webPatch = (pkgs.formats.yaml { }).generate "dsh-web-providers.yml" (
        lib.mapAttrsToList (id: config: { inherit id config; }) cfg.web.settings
      );
    in
    {
      options.my.programs.dsh = {
        enable = lib.mkEnableOption "DeepSeek Harness";
        telemetry.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Export numeric LLM usage without session content.";
        };
        telemetry.endpoint = lib.mkOption {
          type = lib.types.str;
          default =
            if osConfig.my.services.agentTelemetry.enable or false then
              "http://127.0.0.1:4318/v1/metrics"
            else
              "http://B450M-Pro4.tail29d068.ts.net:4318/v1/metrics";
          description = "OTLP HTTP metrics endpoint.";
        };
        web = {
          enable = lib.mkEnableOption "DeepSeek Harness Web";
          autoAuth = lib.mkEnableOption "NixKits-style automatic browser sign-in on a trusted network";
          settings = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
            default = { };
            description = "Plugin entry config overrides applied through a declarative --patch layer. Use credential references, not secret values.";
          };
          backendPort = lib.mkOption {
            type = lib.types.port;
            default = 3082;
            description = "Loopback dsh port when automatic sign-in is enabled.";
          };
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Concrete local IP address on which to listen.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 3081;
          };
          publicUrl = lib.mkOption {
            type = lib.types.str;
            description = "Browser-visible HTTP(S) root URL, including the trailing slash.";
          };
          trustedHosts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional host or host:port authorities accepted by the API trust fence.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ package ];
        systemd.user.services.dsh-web-proxy = lib.mkIf (
          cfg.web.enable && cfg.web.autoAuth
        ) autoAuth.service;
        systemd.user.services.dsh-web = lib.mkIf cfg.web.enable {
          Unit.Description = "DeepSeek Harness Web";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = (if cfg.web.autoAuth then autoAuth.wrap else command: command) (
              lib.escapeShellArgs (
                [
                  "${package}/bin/dsh"
                  "--profile"
                  "web"
                ]
                ++ lib.optionals (cfg.web.settings != { }) [
                  "--patch"
                  (toString webPatch)
                ]
                ++ [
                  "--no-open"
                  "--host"
                  (if cfg.web.autoAuth then "127.0.0.1" else cfg.web.host)
                  "--port"
                  (toString (if cfg.web.autoAuth then cfg.web.backendPort else cfg.web.port))
                  "--public-url"
                  cfg.web.publicUrl
                ]
                ++ lib.concatMap (host: [
                  "--trusted-host"
                  host
                ]) cfg.web.trustedHosts
              )
            );
            WorkingDirectory = config.home.homeDirectory;
            Environment = [
              "HOME=${config.home.homeDirectory}"
              "PATH=${
                lib.concatStringsSep ":" (
                  config.home.sessionPath
                  ++ [
                    "${config.home.profileDirectory}/bin"
                    "/run/wrappers/bin"
                    "/run/current-system/sw/bin"
                  ]
                )
              }"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
            ];
            Restart = "on-failure";
            RestartSec = 5;
            UMask = "0077";
          }
          // lib.optionalAttrs cfg.web.autoAuth autoAuth.backendService;
        };
      };
    };
}
