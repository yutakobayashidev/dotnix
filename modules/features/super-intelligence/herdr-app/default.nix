_:

{
  flake.modules.homeManager.herdr-app =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      threadsSrc = pkgs.fetchFromGitHub {
        owner = "atuinsh";
        repo = "herdr-atuin-threads";
        rev = "6e2786d1ae7555cbe4c338c55c265badc86812cb";
        hash = "sha256-y7YjVtnCRjC/8eaGKAlsJJtCdc9gyikweL0cpj9+Ufg=";
      };
    in
    {
      options.my.programs.herdr-app.enable = lib.mkEnableOption "Herdr desktop app";

      config = lib.mkIf config.my.programs.herdr-app.enable {
        home.packages = [ pkgs.llm-agents.herdr-app ];

        xdg.configFile = lib.mkIf config.programs.atuin.enable {
          "herdr-app/mods/atuin-threads" = {
            source = "${threadsSrc}/mods/atuin-threads";
            recursive = true;
          };
          "herdr-app/mods/atuin-threads/local.json".text = builtins.toJSON {
            atuin = lib.getExe config.programs.atuin.package;
          };
          "herdr-app/keys.json".text = builtins.toJSON {
            global = {
              ${if pkgs.stdenv.hostPlatform.isDarwin then "cmd-shift-t" else "ctrl-shift-t"} =
                "mod.open:atuin-threads";
            };
          };
        };
      };
    };
}
