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

      opencodeConfig = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        autoupdate = false;
        logLevel = "DEBUG";
        provider.lmstudio = {
          npm = "@ai-sdk/openai-compatible";
          name = "LM Studio (x870-stell-legend)";
          options.baseURL = "http://x870-stell-legend.tail29d068.ts.net:1234/v1";
          models = {
            "google/gemma-4-26b-a4b-qat".name = "Gemma 4 26B A4B QAT (LM Studio)";
            "google/gemma-4-26b-a4b".name = "Gemma 4 26B A4B (LM Studio)";
          };
        };
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
        # OpenCode package
        home.packages = lib.mkAfter [ pkgs.llm-agents.opencode ];

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
                exec ${pkgs.llm-agents.opencode}/bin/opencode web --hostname ${lib.escapeShellArg cfg.web.host} --port ${toString cfg.web.port}
              ''
            );
            WorkingDirectory = config.home.homeDirectory;
            EnvironmentFile = cfg.web.environmentFile;
            # Keep `opencode web` from opening a browser in the desktop session.
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
