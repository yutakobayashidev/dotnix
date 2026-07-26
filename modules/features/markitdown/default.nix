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
      markitdown = lib.getExe' package "markitdown";
    in
    {
      options.my.programs.markitdown.enable = lib.mkEnableOption "MarkItDown";

      config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
        home.packages = [ package ];

        programs.agent-skills.skills.explicit.markdown-converter = {
          from = "agent-scripts";
          path = "markdown-converter";
          packages = [ package ];
          rewriteCommands = false;
          transform =
            { original, ... }:
            builtins.replaceStrings
              [
                "uvx markitdown"
                " — no installation required"
                "- First run caches dependencies; subsequent runs are faster"
              ]
              [
                markitdown
                ""
                "- MarkItDown is installed via Nix"
              ]
              original;
        };
      };
    };
}
