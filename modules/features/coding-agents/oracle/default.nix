_:

{
  flake.modules.homeManager."oracle" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      cfg = config.my.programs.oracle;
      oracleBin = lib.getExe pkgs.oracle;
    in
    {
      options.my.programs.oracle.enable = lib.mkEnableOption "Oracle";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.oracle ];

        programs.agent-skills = {
          sources.oracle = registrySources.oracle;

          skills.explicit.oracle = {
            from = "oracle";
            path = ".";
            packages = [ pkgs.oracle ];
            rewriteCommands = false;
            transform =
              { original, dependencies }:
              (builtins.replaceStrings [ "npx -y @steipete/oracle " ] [ "${oracleBin} " ] original)
              + "\n"
              + dependencies;
          };
        };
      };
    };
}
