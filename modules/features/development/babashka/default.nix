_:

{
  flake.modules.homeManager."babashka" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.babashka;
    in
    {
      options.my.programs.babashka.enable = lib.mkEnableOption "Babashka";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.babashka ];

        programs.agent-skills.skills.explicit.babashka-nrepl = {
          from = "local";
          path = "babashka-nrepl";
          packages = [ pkgs.babashka ];
        };
      };
    };
}
