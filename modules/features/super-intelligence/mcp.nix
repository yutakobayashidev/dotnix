_:

{
  flake.modules.homeManager."mcp" =
    {
      inputs,
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.mcp;
    in
    {
      imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

      options.my.programs.mcp = {
        enable = lib.mkEnableOption "Model Context Protocol Servers";

        grafana.sopsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Sops file containing grafana-mcp-token; setting it enables Grafana MCP.";
        };

      };

      config = lib.mkIf cfg.enable {
        sops.secrets = lib.optionalAttrs (cfg.grafana.sopsFile != null) {
          grafana-mcp-token.sopsFile = cfg.grafana.sopsFile;
        };

        programs.mcp = {
          enable = true;

          servers = {
            deepwiki = {
              url = "https://mcp.deepwiki.com/mcp";
            };

            atuin = {
              command = lib.getExe pkgs.atuin;
              args = [ "mcp" ];
            };
          };
        };

        mcp-servers = {
          programs = {
            grafana = lib.mkIf (cfg.grafana.sopsFile != null) {
              enable = true;
              env.GRAFANA_URL = "https://grafana.home.yutakobayashi.com";
              passwordCommand.GRAFANA_SERVICE_ACCOUNT_TOKEN = [
                "${pkgs.coreutils}/bin/cat"
                config.sops.secrets.grafana-mcp-token.path
              ];
            };
            context7.enable = true;
            playwright.enable = true;
            time = {
              enable = true;
              args = [ "--local-timezone=Asia/Tokyo" ];
            };
          };

          settings.servers = {
            searxng = {
              command = lib.getExe pkgs.mcp-searxng;
              env.SEARXNG_URL = "https://search.home.yutakobayashi.com";
            };
          };
        };
      };
    };
}
