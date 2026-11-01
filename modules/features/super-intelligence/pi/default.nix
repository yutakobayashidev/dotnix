_:

{
  flake.modules.homeManager."pi" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.pi;
    in
    {
      options.my.programs.pi = {
        enable = lib.mkEnableOption "Pi";
        acp.enable = lib.mkEnableOption "Pi ACP adapter";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.pi ] ++ lib.optional cfg.acp.enable pkgs.pi-acp;
      };
    };
}
