_:

{
  flake.modules.homeManager.chatgpt =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.chatgpt;
    in
    {
      options.my.programs.chatgpt.enable = lib.mkEnableOption "ChatGPT Desktop";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.chatgpt ];
      };
    };
}
