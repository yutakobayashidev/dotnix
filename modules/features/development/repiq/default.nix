_:

{
  flake.modules.homeManager."repiq" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.repiq;
    in
    {
      options.my.programs.repiq.enable = lib.mkEnableOption "repiq";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.repiq ];

        programs.agent-skills = {
          sources.repiq = {
            path = inputs.repiq;
            subdir = "skills";
          };
          skills.enableAll = [ "repiq" ];
        };
      };
    };
}
