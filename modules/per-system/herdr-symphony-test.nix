{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        herdr-symphony-module =
          let
            result = import ../../tests/herdr-symphony.nix {
              inherit pkgs;
              homeManager = inputs.home-manager;
            };
          in
          assert result.passed;
          pkgs.runCommand "herdr-symphony-module-check" { nativeBuildInputs = [ pkgs.herdr-symphony ]; } ''
            export HOME="$TMPDIR"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            herdr-symphony validate ${result.generatedWorkflow} ${lib.escapeShellArgs result.hostWorkflowFiles}
            touch "$out"
          '';
      };
    };
}
