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
      boardSrc = pkgs.fetchFromGitHub {
        owner = "herdrdev";
        repo = "herdr-layout-examples";
        rev = "0ec967640bf854ffb839e9af06c1e0c328bc9815";
        hash = "sha256-vrA4BkUrIVQZrOFhfzCSTjQFygjldQx9pB80tOcudzI=";
      };
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

        programs.agent-skills = {
          # Keep the entry point in step with the installed core. The detailed
          # manuals are supplied by hc --skill and herdr-app --skill at runtime.
          sources.herdr-core.path = "${pkgs.llm-agents.herdr-core.src}/skills/herdr-core";
          skills.explicit.herdr-core = {
            from = "herdr-core";
            path = ".";
            rewriteCommands = false;
          };
        };

        xdg.configFile = {
          "herdr-app/layouts/board.json".source = "${boardSrc}/board/layouts/board.json";
          "herdr-app/mods/board" = {
            source = "${boardSrc}/board/mods/board";
            recursive = true;
          };
        }
        // lib.optionalAttrs config.programs.atuin.enable {
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
