# Herdr Symphony

UM790-Pro runs `herdr-symphony.service` as a systemd user service. It polls the private [Agent Work Queue](https://github.com/users/yutakobayashidev/projects/3) every 30 seconds and starts at most one interactive Codex agent per workflow (up to two across different issues) through Herdr Core (`hc`). The host workflow pins `gpt-6.2-astra` with `medium` reasoning effort. Codex runs with `--no-daemon`, keeps its configured approval/sandbox policy, and reports completion using `herdr-symphony report`. First use of a repository may require trusting its worktree in the Codex terminal. Symphony does not embed an App Server client.

## Module boundaries

- NUR packages the CLI; `package` selects the derivation.
- `modules/features/super-intelligence/herdr-symphony/default.nix` implements the Home Manager service, workflow materialization, and runtime environment. It contains no owner, Project number, agent choice, repository root, or prompt policy.
- `homes/nixos/UM790-Pro/herdr-symphony/default.nix` selects the runner and Project and supplies the workflow settings. `common.md`, `implement.md`, `verify.md`, and `visual-validation.md` supply the Liquid prompt bodies. Shared runner, environment, workspace and tracker settings are defined once in the host module.

The input model follows [nix-openclaw's separation of configuration, runtime packages, and environment](https://github.com/openclaw/nix-openclaw/blob/0992734dee124e27cfc7a614d3af444240aec39e/nix/modules/home-manager/openclaw/options-instance.nix). Symphony workflows share a process rather than using OpenClaw-style independent instances: the in-process claim registry prevents double dispatch across workflows. Concurrency limits remain per workflow, not global across all workflows.

## Workflow inputs

Choose one input mode per named workflow. An existing complete workflow is copied unchanged:

```nix
my.services.herdr-symphony = {
  enable = true;
  workflows.default.source = ./WORKFLOW.md;
};
```

Alternatively, use native Symphony keys in `settings`, with a separate prompt file:

```nix
my.services.herdr-symphony.workflows.default = {
  settings = {
    tracker = {
      kind = "github_project";
      github_project = { owner = "example"; number = 1; };
    };
    work.runner = "herdr_core";
  };
  promptFile = ./prompt.md;
};
```

`prompt` accepts inline text instead of `promptFile`. These examples describe the input forms; supply runner, agent, and workspace settings for your deployment as shown in the UM790-Pro host configuration.

Home Manager serializes `settings` as JSON (valid YAML) with `pkgs.formats.json` and combines it with the prompt. This avoids YAML document directives colliding with Markdown frontmatter delimiters. Settings merge through the Nix module system; the application owns schema validation. `source` cannot be combined with generated settings or prompt inputs. `prompt` and `promptFile` are also mutually exclusive. No `@HOME@` or `@PATH@` substitution takes place. Use Nix interpolation in `settings`; Liquid expressions remain for Symphony to evaluate per issue.

`workflows.default` retains the stable `~/.config/herdr-symphony/WORKFLOW.md` path. Other names become `~/.config/herdr-symphony/workflows/<name>.md`. All are passed to one service. Names must contain only letters, digits, underscores, and hyphens; renaming a workflow changes its persistent identity. Home Manager restarts the service when a managed workflow changes.

## Runtime inputs and state

`path` lists packages or profile roots whose `bin` directories are visible to the service, in addition to the Symphony package. The default includes Git, GitHub CLI and coreutils; add the chosen runner and agent explicitly. `environment` supplies non-secret values and can override the generated `PATH`. UM790-Pro explicitly forwards that PATH through the workflow's agent environment because `hc` uses its core's environment for new terminals.

`environmentFiles` accepts absolute runtime path **strings**, for example `[ "/run/user/1000/symphony.env" ]`. systemd reads them at service startup; Nix never reads their contents. EnvironmentFile values override `environment`. They affect Symphony's process, and are not automatically forwarded to agents. Do not put tokens in settings, prompt files, or environment values: those inputs enter the Nix store. This deployment uses the existing `gh` credentials with `project` and `user` scopes and creates no new token file.

`stateDirectory` defaults to `${config.xdg.stateHome}/herdr-symphony`. The launcher creates it with mode 0700, changes into it, and executes Symphony. The database remains in `.workaholic/` beneath that directory, separate from immutable configuration. Changing workflow contents does not change its path or the state directory. This module supports Linux systemd user services; it does not implement launchd or manage linger. Linger is already enabled for yuta.

## Operations

Issues belong to their target repositories. Add an issue to the Project and move it from `Todo` to `Implement` to authorize execution. Symphony resolves the repository with `ghq list -p -e <owner>/<repo>`, respecting the configured ghq root. Clone it with `ghq get` before moving the issue to Implement; missing repositories are not cloned automatically. Draft items are skipped.

Worktrees use the `git-wt` provider, invoking `git wt --nocd -- <branch>`. Paths come from `git wt --json`; `wt.basedir`, copy rules and creation hooks are honored. Existing worktrees are reused by branch without rerunning creation hooks. The current dotnix configuration sets `wt.basedir = .git/worktree`. Do not set Symphony workspace `path` or `base_dir` for this provider. A failed creation hook can leave a worktree behind; inspect and repair it before retrying. Before creating a new branch, Symphony fetches `origin` and passes the default branch that `origin/HEAD` points to as the git-wt start point, so the branch does not depend on the repository root's checkout. Existing local branches are reused; remote-only branches are left to git-wt. A failed fetch aborts creation and the dispatch is retried. Repositories without `origin` or `origin/HEAD` start from the repository root's HEAD.

The two workflows implement this loop:

```text
Implement -> In progress -> Verify -> Verifying -> In review -> human merge
    ^                                    |
    +------------- changes needed -------+
```

`implement` reads the latest issue comments and all PR feedback, updates the existing branch/PR, merges the fetched default branch, runs local and visual validation, then reports completion. A conflict that cannot be resolved from the requirements, code and tests aborts the merge and reports failure. Symphony moves a completed run to `Verify`. `verify` independently reviews the current head, checks CI, mergeability and media, and chooses `In review`, `Implement`, or `Blocked`. It updates the Project item, verifies the new status, and reports completion; its `success_state = null` preserves that decision. Infrastructure failures and timeouts go to `Blocked`. Both phases share the same worktree and record successful phase summaries in the Issue's Agent Logs. A verification finding is a successful verification run with an Implement verdict, not a process failure.

For human revisions, comment on the PR and move the original Issue's Project item from `In review` to `Implement`. This starts a new Codex session on the existing worktree. Comments alone do not trigger execution. Avoid sending follow-up work to a completed terminal scheduled for cleanup.

The verify prompt treats missing required CI, zero checks, skipped/cancelled required checks and unavailable verification as non-passing. It stops repeated unchanged findings at `Blocked` after three verification rounds. These are agent instructions, not additional deterministic enforcement in Symphony; target repository branch protection remains the merge guard. Neither workflow merges or enables auto-merge. The human merges. PR bodies contain `Closes <owner>/<repo>#<number>`, so the merge closes the Issue and the default Project workflow marks the item `Done`.

Dependencies use GitHub issue relationships (`blocked by`). Symphony's built-in blocker check does not apply to GitHub Projects: it runs only for `Todo`/`Backlog` items and compares the blocker's issue state (`OPEN`/`CLOSED`) with Status names. The implement workflow therefore renders `work.if` false while any blocker is still open. Dependent items can wait in `Implement` and start on the first poll after every blocker closes. An item marked `Done` without closing its Issue keeps its dependents waiting. Skipped items appear only in debug logs (`reason=if_condition`).

Project 3 keeps the former Ready option ID under the name `Implement` and adds `Verify` and `Verifying`. Existing Done/Blocked items retain their state. Renaming `default` to `implement`/`verify` changes workflow persistence identities, so apply this migration only when the old workflow has no running task. The old WORKFLOW.md is no longer an active service input.

```sh
systemctl --user status herdr-symphony
journalctl --user -u herdr-symphony -f
systemctl --user stop herdr-symphony
```

Stopping Symphony stops polling; Herdr Core agents already started can continue. Inspect and stop those separately if needed. Runtime credentials changed in EnvironmentFiles require a service restart.

The package is maintained in [NUR PR #21](https://github.com/yutakobayashidev/nur-packages/pull/21); dotnix pins its published commit. After merging, the input URL can return to the default branch and the lock can be updated.

Initial installation applies only the generated unit and workflow rather than switching unrelated pending system changes. A `service-closure` GC root in the state directory protects this initial closure. Subsequent Home Manager activation can manage the same paths.

## Module checks

From this repository:

```sh
nix eval --impure --json --expr '
  let f = builtins.getFlake (toString ./.);
  in import ./tests/herdr-symphony.nix {
    pkgs = f.nixosConfigurations.UM790-Pro.pkgs;
    homeManager = f.inputs.home-manager;
  }'
```

The tests evaluate real Home Manager configurations for disabled mode, generated and existing workflow inputs, multiple workflows, runtime EnvironmentFiles and conflicting inputs. Validate materialized workflows with `herdr-symphony validate <file>` before restarting the service.

Run the reproducible materialization and application-parser check with `nix build .#checks.x86_64-linux.herdr-symphony-module`.

Symphony closes its recorded Herdr terminal five minutes after success, failure or timeout, on the next polling sweep. Independently started terminals are not enumerated or closed. Reusing a scheduled terminal does not cancel its cleanup; use a separate terminal for follow-up work. The setting is captured when a task starts and does not retroactively clean up old terminals. Pending cleanup timers are in memory and are lost when Symphony restarts.

The host service uses the user profile and `/run/current-system/sw` for its tools. Node.js is added explicitly because it is not on those profiles and the media attachment formatter needs it. The module adds Symphony itself to PATH and the host forwards the same PATH to Codex started by Herdr Core.

## Dedicated App space and history

UM790-Pro sends workers to the `Symphony Tasks` space through `herdr_agent.app_space`. Each issue receives its own tab; the Queue shell keeps the named space available after workers close. The App can be closed while Core runs tasks. If the space is deleted, the next worker recreates its configured ID as an unnamed space; rename it or update the ID in the host configuration.

The service and Codex share `cfg.environment`, with PATH from the profiles, CODEX_HOME from Home Manager session variables, and the XDG directories from Home Manager. Atuin uses those same configured directories to ingest Codex threads and tool commands. Direct service commands do not become interactive shell history. App Threads also requires an Atuin client compatible with the running daemon.
