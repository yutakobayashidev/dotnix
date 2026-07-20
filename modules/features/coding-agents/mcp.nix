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
      ghidraWithMcp = pkgs.ghidra-mcp.ghidra.withExtensions (_: [ pkgs.ghidra-mcp ]);
    in
    {
      imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

      options.my.programs.mcp = {
        enable = lib.mkEnableOption "Model Context Protocol Servers";

        ghidra = {
          enable = lib.mkEnableOption "GhidraMCP integration";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Host running the GhidraMCP HTTP extension.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 38473;
            description = "Port used by the GhidraMCP HTTP extension.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = lib.optional cfg.ghidra.enable ghidraWithMcp;

        programs.mcp = {
          enable = true;

          servers = {
            deepwiki = {
              url = "https://mcp.deepwiki.com/mcp";
            };

            junction = {
              url = "https://junction-mcp-up7swxs6gq-an.a.run.app/mcp";
              oauth_resource = "https://junction-mcp-up7swxs6gq-an.a.run.app/mcp";
            };
          };
        };

        mcp-servers = {
          programs = {
            context7.enable = true;
            playwright.enable = true;
            time = {
              enable = true;
              args = [ "--local-timezone=Asia/Tokyo" ];
            };
          };

          settings.servers = lib.mkIf cfg.ghidra.enable {
            ghidra = {
              command = lib.getExe pkgs.ghidra-mcp-bridge;
              args = [ "http://${cfg.ghidra.host}:${toString cfg.ghidra.port}" ];
            };
          };
        };
      };
    };
}
