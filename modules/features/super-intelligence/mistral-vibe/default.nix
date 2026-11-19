_:

{
  flake.modules.homeManager."mistral-vibe" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.mistral-vibe;
    in
    {
      options.my.programs.mistral-vibe.enable = lib.mkEnableOption "Mistral Vibe CLI";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.mistral-vibe ];
      };
    };
}
