{
  pkgs,
  lib,
  registrySources,
}:
let
  source = registrySources.mizchi.path;
  python = lib.getExe pkgs.python3;
  lint = "${python} ${source}/ai-index/scripts/slopscore.py";
  # measure.ts and check-draft.ts invoke gh as a subprocess.
  node = "${pkgs.coreutils}/bin/env PATH=${
    lib.makeBinPath [
      pkgs.gh
      pkgs.git
    ]
  }:$PATH ${lib.getExe pkgs.nodejs_24}";

  writing = name: {
    from = "mizchi";
    path = name;
    packages = [ pkgs.python3 ];
    rewriteCommands = false;
    transform = { original, dependencies }: ''
      ${builtins.replaceStrings
        [ "python3 ../ai-index/scripts/slopscore.py" "ai-index/references/calibration.md" ]
        [ lint "${source}/ai-index/references/calibration.md" ]
        original
      }

      ${dependencies}
    '';
  };
in
{
  maintainer-persona = {
    from = "mizchi";
    path = "maintainer-persona";
    packages = [
      pkgs.nodejs_24
      pkgs.gh
      pkgs.git
      pkgs.python3
    ];
    rewriteCommands = false;
    transform = { original, dependencies }: ''
      ${builtins.replaceStrings
        [
          "S=$SK/scripts"
          "A=$SK/../ai-index/scripts/slopscore.py"
          "node $S/"
          "python3 $A"
          ''
            If one is missing, install it (`apm install -g
            mizchi/skills/<name>`); if that is not possible, report the step as skipped.''
          "# Maintainer Persona"
        ]
        [
          "S=${source}/maintainer-persona/scripts"
          "A=${source}/ai-index/scripts/slopscore.py"
          "${node} $S/"
          "${python} $A"
          "These skills are installed together by dotnix. If one is missing, report the missing skill and fix the Nix selection; do not install it with APM."
          ''
            # Maintainer Persona

            ## Local workflow policy

            This policy takes precedence over the approval stages below. For analysis-only
            requests, stop after producing the persona; drafting and posting are separate
            tasks. For an authorized drafting task, finish the Japanese draft, translation,
            lint and fresh-reader review before presenting the final result. Reuse the
            user's existing authorization instead of requesting approval at every stage.
            Sending or editing an external issue, PR or comment requires authorization
            covering that action; analysis or draft approval alone does not authorize it.
            Keep persona and corpus files in the working repository, never the Nix store.
          ''
        ]
        original
      }

      ${dependencies}
    '';
  };

  natural-writing-ja = writing "natural-writing-ja";
  natural-writing-en = writing "natural-writing-en";

  ai-index = {
    from = "mizchi";
    path = "ai-index";
    packages = [ pkgs.python3 ];
    rewriteCommands = false;
    transform = { original, dependencies }: ''
      ${builtins.replaceStrings
        [ "python3 scripts/slopscore.py" "--baseline fixtures/*.md" ]
        [ lint "--baseline ${source}/ai-index/fixtures/*.md" ]
        original
      }

      ${dependencies}
    '';
  };

  extract-glossary = {
    from = "mizchi";
    path = "extract-glossary";
  };
  stryker-js = {
    from = "mizchi";
    path = "stryker-js";
  };
  formal-methods-reconciler = {
    from = "mizchi";
    path = "formal-methods-reconciler";
  };
}
