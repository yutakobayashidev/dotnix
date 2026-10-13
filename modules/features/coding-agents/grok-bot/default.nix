_:

{
  flake.modules.homeManager.grok-bot =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.grok-bot;
    in
    {
      options.my.programs.grok-bot.enable = lib.mkEnableOption "Grok Bot";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.grok-bot ];
      };
    };
}
