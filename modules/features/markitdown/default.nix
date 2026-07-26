_:

{
  flake.modules.homeManager."markitdown" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.markitdown;
      package = pkgs.stable.python313Packages.markitdown;
    in
    {
      options.my.programs.markitdown.enable = lib.mkEnableOption "MarkItDown";

      config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
        home.packages = [ package ];

        programs.agent-skills.skills.explicit.markitdown = {
          from = "local";
          path = "markitdown";
          packages = [ package ];
        };
      };
    };
}
