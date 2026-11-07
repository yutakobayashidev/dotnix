_:

{
  flake.modules.homeManager."dsh" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.dsh;
    in
    {
      options.my.programs.dsh = {
        enable = lib.mkEnableOption "DeepSeek Harness";
        web = {
          enable = lib.mkEnableOption "DeepSeek Harness Web";
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
        home.packages = [ pkgs.llm-agents.dsh ];
        systemd.user.services.dsh-web = lib.mkIf cfg.web.enable {
          Unit.Description = "DeepSeek Harness Web";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = lib.escapeShellArgs (
              [
                "${pkgs.llm-agents.dsh}/bin/dsh"
                "web"
                "--no-open"
                "--host"
                cfg.web.host
                "--port"
                (toString cfg.web.port)
                "--public-url"
                cfg.web.publicUrl
              ]
              ++ lib.concatMap (host: [
                "--trusted-host"
                host
              ]) cfg.web.trustedHosts
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
          };
        };
      };
    };
}
