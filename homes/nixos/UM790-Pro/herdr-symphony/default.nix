{ config, pkgs, ... }:

let
  cfg = config.my.services.herdr-symphony;
  branch = ''herdr/{{ issue.identifier | replace: "/", "_" | replace: "#", "_" }}'';
in
{
  my.services.herdr-symphony = {
    enable = true;
    path = [
      config.home.profileDirectory
      "/run/current-system/sw"
      pkgs.nodejs
    ];
    workflows.default = {
      promptFile = ./prompt.md;
      settings = {
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
          active_states = [ "Ready" ];
          terminal_states = [ "Done" ];
          running_state = "In progress";
          success_state = "In review";
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
            agent = "codex";
            codex = {
              model = "gpt-6.2-astra";
              thinking_effort = "medium";
              env.PATH = cfg.environment.PATH;
            };
            turn_timeout_ms = 3600000;
            close_pane_after_done_ms = 300000;
          };
        };
      };
    };
  };
}
