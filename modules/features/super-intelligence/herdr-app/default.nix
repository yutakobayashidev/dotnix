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
      keysOverrides = pkgs.writeText "herdr-app-keys-overrides.json" (
        builtins.toJSON {
          global = {
            ${if pkgs.stdenv.hostPlatform.isDarwin then "cmd-shift-t" else "ctrl-shift-t"} =
              "layout.switch:dotnix-threads";
          };
          "layout:dotnix-threads" = {
            ${if pkgs.stdenv.hostPlatform.isDarwin then "cmd-shift-t" else "ctrl-shift-t"} =
              "layout.toggle:atuin-threads-panel";
          };
        }
      );
      # Herdr replaces its defaults with keys.json rather than merging them.
      # Merge at build time so the defaults track the installed package.
      keysFile = pkgs.runCommand "herdr-app-keys.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
        jq -s '.[0] * .[1]' \
          ${pkgs.llm-agents.herdr-app.src}/defaults/${
            if pkgs.stdenv.hostPlatform.isDarwin then "keys.macos.json" else "keys.json"
          } \
          ${keysOverrides} > "$out"
      '';
    in
    {
      options.my.programs.herdr-app.enable = lib.mkEnableOption "Herdr desktop app";

      config = lib.mkIf config.my.programs.herdr-app.enable {
        home.packages = [
          pkgs.llm-agents.herdr-app
          pkgs.llm-agents.herdr-core
        ];

        xdg.configFile = lib.mkIf config.programs.atuin.enable {
          "herdr-app/layouts/dotnix-threads.json".source = ./layout.json;
          "herdr-app/layouts/dotnix-threads.svg".source = ./layout.svg;
          "herdr-app/mods/atuin-threads" = {
            source = "${threadsSrc}/mods/atuin-threads";
            recursive = true;
          };
          "herdr-app/mods/atuin-threads/local.json".text = builtins.toJSON {
            atuin = lib.getExe config.programs.atuin.package;
          };
          "herdr-app/keys.json".source = keysFile;
        };
      };
    };
}
