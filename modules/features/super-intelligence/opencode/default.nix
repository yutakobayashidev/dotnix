_:

{
  flake.modules.homeManager."opencode" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.my.programs.opencode;
      opencode = pkgs.writeShellScriptBin "opencode" ''
        exec ${lib.getExe pkgs.llm-agents.opencode2} "$@"
      '';

      opencodeConfig = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        update = "disable";
        providers.ollama.settings.baseURL = "http://x870-stell-legend.tail29d068.ts.net:11434/v1";
      };
    in
    {
      options.my.programs.opencode = {
        enable = lib.mkEnableOption "OpenCode";
        web = {
          enable = lib.mkEnableOption "OpenCode Web";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 4096;
          };
          environmentFile = lib.mkOption {
            type = lib.types.str;
            description = "Runtime environment file containing OPENCODE_SERVER_PASSWORD; never a Nix store path.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        # Keep the usual command name while llm-agents packages V2 as opencode2.
        home.packages = lib.mkAfter [
          pkgs.llm-agents.opencode2
          opencode
        ];

        systemd.user.services.opencode-web = lib.mkIf cfg.web.enable {
          Unit.Description = "OpenCode Web";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = lib.getExe (
              pkgs.writeShellScriptBin "opencode-web-start" ''
                if [ -z "''${OPENCODE_SERVER_PASSWORD:-}" ]; then
                  echo "OPENCODE_SERVER_PASSWORD must not be empty" >&2
                  exit 1
                fi
                exec ${lib.getExe pkgs.llm-agents.opencode2} serve --hostname ${lib.escapeShellArg cfg.web.host} --port ${toString cfg.web.port}
              ''
            );
            WorkingDirectory = config.home.homeDirectory;
            EnvironmentFile = cfg.web.environmentFile;
            # The headless service does not need a desktop session.
            UnsetEnvironment = [
              "DISPLAY"
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
            ];
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
              "BROWSER=${pkgs.coreutils}/bin/true"
            ];
            Restart = "on-failure";
            RestartSec = 5;
            UMask = "0077";
          };
        };

        # Generate opencode.json
        xdg.configFile."opencode/opencode.json" = {
          text = opencodeConfig;
        };
      };
    };
}
