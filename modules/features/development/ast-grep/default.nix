_:

{
  flake.modules.homeManager."ast-grep" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.ast-grep;
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      astGrepBin = lib.getExe pkgs.ast-grep;
    in
    {
      options.my.programs.ast-grep.enable = lib.mkEnableOption "ast-grep";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.ast-grep ];

        programs.agent-skills = {
          sources.ast-grep = registrySources.ast-grep;
          skills.explicit.ast-grep = {
            from = "ast-grep";
            path = "ast-grep";
            packages = [ pkgs.ast-grep ];
            rewriteCommands = false;
            transform =
              { original, dependencies }:
              let
                patched =
                  builtins.replaceStrings
                    [ "| ast-grep " "ast-grep scan " "ast-grep run " ]
                    [ "| ${astGrepBin} " "${astGrepBin} scan " "${astGrepBin} run " ]
                    original;
              in
              ''
                ${patched}

                ${dependencies}
              '';
          };
        };
      };
    };
}
