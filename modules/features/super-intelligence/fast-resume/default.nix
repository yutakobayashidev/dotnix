_:

{
  flake.modules.homeManager.fast-resume =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      package = pkgs.fast-resume.overrideAttrs (old: {
        # CODEX_HOME subset of https://github.com/angristan/fast-resume/pull/112.
        # Drop when the nixpkgs package includes upstream storage overrides.
        patches = (old.patches or [ ]) ++ [ ./codex-home.patch ];
      });
    in
    {
      options.my.programs.fast-resume.enable = lib.mkEnableOption "fast-resume session search";

      config = lib.mkIf config.my.programs.fast-resume.enable {
        home.packages = [ package ];
      };
    };
}
