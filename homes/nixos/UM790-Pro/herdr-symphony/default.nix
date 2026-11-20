{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.herdr-symphony;
  branch = ''herdr/{{ issue.identifier | replace: "/", "_" | replace: "#", "_" }}'';
  commonSettings = {
    tracker = {
      kind = "github_project";
      github_project = {
        owner = "yutakobayashidev";
        number = 3;
      };
    };
    polling.interval_ms = 30000;
    agent = {
      max_concurrent_agents = 1;
      max_retry_backoff_ms = 300000;
    };
    work = {
      "if" = "{% if issue.repository %}true{% else %}false{% endif %}";
      terminal_states = [ "Done" ];
      failure_state = "Blocked";
      reporter = [
        "file"
        "tracker"
      ];
      workspace = {
        provider = "git-wt";
        inherit branch;
        reuse_existing = true;
        create_if_missing = true;
      };
      runner = "herdr_core";
      herdr_agent = {
        agent = "claude";
        app_space = "spe197553d6d39c7e2fbf69dde3e4806e7";
        claude = {
          permission_mode = "bypassPermissions";
          env = cfg.environment;
        };
        codex = {
          yolo = true;
          model = "gpt-6.2-astra";
          thinking_effort = "medium";
          env = cfg.environment;
        };
        turn_timeout_ms = 3600000;
        close_pane_after_done_ms = 300000;
      };
    };
  };
  commonPrompt = builtins.readFile ./common.md;
  projectStatusPrompt = builtins.readFile ./project-status.md;
in
{
  my.services.herdr-symphony = {
    enable = true;
    path = [
      config.home.profileDirectory
      "/run/current-system/sw"
      pkgs.nodejs
    ];
    environment =
      lib.filterAttrs (
        name: _:
        builtins.elem name [
          "CLAUDE_CONFIG_DIR"
          "CODEX_HOME"
        ]
      ) config.home.sessionVariables
      // {
        XDG_CONFIG_HOME = config.xdg.configHome;
        XDG_DATA_HOME = config.xdg.dataHome;
        XDG_STATE_HOME = config.xdg.stateHome;
        XDG_CACHE_HOME = config.xdg.cacheHome;
      };
    workflows = {
      implement = {
        settings = lib.recursiveUpdate commonSettings {
          work = {
            # Symphony's built-in blocker check does not apply to GitHub Projects;
            # wait here until every "blocked by" issue is closed.
            "if" =
              ''{% assign open_blockers = issue.blockedBy | where: "state", "OPEN" | size %}{% if issue.repository and open_blockers == 0 %}true{% else %}false{% endif %}'';
            active_states = [ "Implement" ];
            running_state = "In progress";
            success_state = "Verify";
          };
        };
        prompt =
          commonPrompt
          + "\n"
          + builtins.readFile ./implement.md
          + "\n"
          + builtins.readFile ./visual-validation.md;
      };
      verify = {
        settings = lib.recursiveUpdate commonSettings {
          work = {
            active_states = [ "Verify" ];
            running_state = "Verifying";
            success_state = null;
          };
        };
        prompt = commonPrompt + "\n" + builtins.readFile ./verify.md + "\n" + projectStatusPrompt;
      };
      merge = {
        settings = lib.recursiveUpdate commonSettings {
          work = {
            active_states = [ "Merging" ];
            running_state = "Landing";
            success_state = null;
          };
        };
        prompt = commonPrompt + "\n" + builtins.readFile ./merge.md + "\n" + projectStatusPrompt;
      };
    };
  };
}
