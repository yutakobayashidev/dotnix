_:

{
  flake.modules.homeManager."edcb-tools" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.edcb-tools;
    in
    {
      options.my.programs.edcb-tools.enable = lib.mkEnableOption "EDCB tools";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.edcb-tools ];

        programs.agent-skills = {
          sources.edcb-tools = {
            path = inputs.edcb-tools;
            subdir = ".agents/skills";
          };
          skills.explicit.edcb-tools = {
            from = "edcb-tools";
            path = "edcb-tools";
            packages = [ pkgs.edcb-tools ];
          };
        };
      };
    };
}
