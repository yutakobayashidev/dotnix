{ pkgs, homeManager }:
let
  inherit (pkgs) lib;
  module =
    (import ../modules/features/super-intelligence/herdr-symphony/default.nix { })
    .flake.modules.homeManager.herdr-symphony;
  evaluate =
    extra:
    (homeManager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        module
        {
          home = {
            username = "tester";
            homeDirectory = "/home/tester";
            stateVersion = "25.11";
          };
        }
        extra
      ];
    }).config;
  base = {
    my.services.herdr-symphony = {
      enable = true;
      workflows.default = {
        settings.tracker = {
          kind = "github_project";
          github_project = {
            owner = "example";
            number = 1;
          };
        };
        prompt = "Issue: {{ issue.title }}";
      };
    };
  };
  disabled = evaluate { };
  generated = evaluate base;
  files = evaluate {
    my.services.herdr-symphony = {
      enable = true;
      workflows.default.source = builtins.toFile "workflow-input.md" "---\ntracker: {}\n---\nPrompt\n";
      workflows.secondary.source = builtins.toFile "second-input.md" "---\ntracker: {}\n---\nSecond\n";
      environmentFiles = [ "/run/user/1000/symphony.env" ];
    };
  };
  conflict = evaluate (
    lib.recursiveUpdate base {
      my.services.herdr-symphony.workflows.default.source = builtins.toFile "conflict.md" "raw";
    }
  );
  promptConflict = evaluate (
    lib.recursiveUpdate base {
      my.services.herdr-symphony.workflows.default.promptFile = builtins.toFile "prompt.md" "prompt";
    }
  );
  merged = evaluate {
    imports = [
      base
      { my.services.herdr-symphony.workflows.default.settings.polling.interval_ms = 12000; }
    ];
  };
  empty = evaluate { my.services.herdr-symphony.enable = true; };
  assertValid = c: lib.all (a: a.assertion) c.assertions;
in
assert !(disabled.systemd.user.services ? herdr-symphony);
assert assertValid generated;
assert assertValid files;
assert !(builtins.tryEval (assertValid conflict)).success;
assert !(builtins.tryEval (assertValid promptConflict)).success;
assert !(builtins.tryEval (assertValid empty)).success;
assert merged.my.services.herdr-symphony.workflows.default.settings.polling.interval_ms == 12000;
assert
  merged.my.services.herdr-symphony.workflows.default.settings.tracker.github_project.number == 1;
assert builtins.attrNames files.systemd.user.services == [ "herdr-symphony" ];
assert
  files.xdg.configFile."herdr-symphony/WORKFLOW.md".source
  == files.my.services.herdr-symphony.workflows.default.source;
assert files.xdg.configFile ? "herdr-symphony/workflows/secondary.md";
assert
  files.systemd.user.services.herdr-symphony.Service.EnvironmentFile
  == [ (builtins.toJSON "/run/user/1000/symphony.env") ];
assert
  generated.my.services.herdr-symphony.stateDirectory == "/home/tester/.local/state/herdr-symphony";
{
  passed = true;
  generatedWorkflow = generated.xdg.configFile."herdr-symphony/WORKFLOW.md".source;
}
