_:

{
  flake.modules.homeManager."mcp" =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.my.programs.mcp;
    in
    {
      imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

      options.my.programs.mcp.enable = lib.mkEnableOption "Model Context Protocol Servers";

      config = lib.mkIf cfg.enable {
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

        mcp-servers.programs = {
          context7.enable = true;
          playwright.enable = true;
          time = {
            enable = true;
            args = [ "--local-timezone=Asia/Tokyo" ];
          };
        };
      };
    };
}
