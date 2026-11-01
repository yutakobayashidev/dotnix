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
      options.my.programs.opencode.enable = lib.mkEnableOption "OpenCode";

      config = lib.mkIf cfg.enable {
        # OpenCode package
        home.packages = lib.mkAfter [ pkgs.llm-agents.opencode ];

        # Generate opencode.json
        xdg.configFile."opencode/opencode.json" = {
          text = opencodeConfig;
        };
      };
    };
}
