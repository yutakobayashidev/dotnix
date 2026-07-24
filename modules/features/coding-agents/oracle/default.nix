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
      cfg = config.my.programs.oracle;
      oracleBin = lib.getExe pkgs.oracle;
    in
    {
      options.my.programs.oracle.enable = lib.mkEnableOption "Oracle";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.oracle ];

        programs.agent-skills = {
          sources.oracle = {
            path = inputs.oracle-skill;
            subdir = "skills/oracle";
          };

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
