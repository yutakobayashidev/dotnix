_:

{
  flake.modules.homeManager."obsidian" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.obsidian;
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
    in
    {
      options.my.programs.obsidian.enable = lib.mkEnableOption "Obsidian";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.obsidian ];

        programs.agent-skills = {
          sources.obsidian = registrySources.obsidian;
          # Keep the Obsidian tools without the retired defuddle CLI skill.
          skills.explicit =
            lib.genAttrs
              [
                "json-canvas"
                "knap"
                "obsidian-bases"
                "obsidian-cli"
                "obsidian-markdown"
              ]
              (name: {
                from = "obsidian";
                path = name;
              });
        };
      };
    };
}
