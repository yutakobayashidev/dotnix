_:

{
  flake.modules.homeManager."before-and-after" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.before-and-after;
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      bnaBin = lib.getExe pkgs.before-and-after;
    in
    {
      options.my.programs.before-and-after.enable = lib.mkEnableOption "before-and-after";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.before-and-after ];

        programs.agent-skills = {
          sources.before-and-after = registrySources.before-and-after;
          skills.explicit.before-and-after = {
            from = "before-and-after";
            path = ".";
            packages = [ pkgs.before-and-after ];
            rewriteCommands = false;
            transform =
              { original, ... }:
              builtins.replaceStrings
                [
                  "`which before-and-after || npm install -g @vercel/before-and-after`"
                  "npm install -g @vercel/before-and-after"
                  "npx @vercel/before-and-after"
                ]
                [
                  "`which before-and-after`"
                  "# (installed via Nix)"
                  bnaBin
                ]
                original;
          };
        };
      };
    };
}
