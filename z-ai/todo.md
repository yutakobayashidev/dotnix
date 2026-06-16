# Add Codex External Movie Playback Rule

- [x] Add a Codex permission rule for external movie playback commands.
- [x] Verify the rule examples and diff.
- [x] Record review and documentation impact.

## Plan

Add a focused rule file under `codex/rules/` using the provided
`prefix_rule`. Keep it scoped to `bun run packages/cli/src/index.ts movies play`
and only match the two external playback commands that should allow playback.

# Add HashiCorp Agent Skills To Local Targets

- [x] Add the `hashicorp/agent-skills` flake input.
- [x] Add a flake module that builds a local-target agent-skills shell hook.
- [x] Attach the shell hook to the default dev shell.
- [x] Update the lock file and run focused Nix verification.
- [x] Record review and documentation impact.

## Plan

Keep the provider catalog scoped to `hashicorp/agent-skills` only. Put the
local target bundle logic under `modules/flake/agent-skills`, then have the
default dev shell append that hook after the existing pre-commit hook. Verify by
evaluating the default dev shell and checking formatting/diff cleanliness.

## Review

- Added `hashicorp-agent-skills` as a flake input pinned in `flake.lock`.
- Added `modules/flake/agent-skills`, which discovers only the HashiCorp skill
  catalog, selects all discovered HashiCorp skills, builds a bundle, and enables
  every `agent-skills-nix` default local target.
- Appended the generated local-target install hook to the default dev shell
  after the existing pre-commit installation script.
- `nix fmt`: passed with 0 changed files.
- `nix eval --raw '.#devShells.aarch64-darwin.default.inputDerivation.drvPath'`:
  passed and returned
  `/nix/store/jm7vvwdn9nfviv02kv75sb8hhmwh6qnr-inputDerivation-nix-shell.drv`.
- `nix eval --raw '.#devShells.aarch64-darwin.default.shellHook'`: passed and
  showed the existing pre-commit hook followed by
  `/nix/store/llcczb8a0bvacgii0fpyij3j4vq24gxy-skills-install-local/bin/skills-install-local`.
- Documentation check: simplified `README.md` so it points to the
  agent-skills Nix modules instead of maintaining fixed source/target lists.

# Commit Misc Media Packages

- [x] Review the staged diff for `applications/misc/default.nix`.
- [x] Run a focused Nix evaluation to verify the package list still evaluates.
- [x] Commit the staged change and record doc impact.

## Plan

Inspect the staged diff, keep the change limited to adding `mpv` to the shared
misc package list, and verify with a focused `nix eval` against a known
configuration attribute that includes this module. No README/AGENTS/CLAUDE/docs
update is expected because this only adds one Home Manager package without
changing documented workflows or architecture.

## Review

- The original staged diff also added `ffplay`, but `pkgs.ffplay` is undefined
  in nixpkgs, so the configuration evaluation failed.
- Reduced the final change to a single `mpv` package addition in
  `applications/misc/default.nix`, keeping the existing `ffmpeg` entry intact.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.home.activationPackage.drvPath'`:
  passed and returned
  `/nix/store/y7bzx541swdm2ly5myz28mmk2g96mjq2-home-manager-generation.drv`.
- `git diff --check`: passed.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because this
  only adds one shared Home Manager package and does not change commands,
  workflows, or architecture.

# Fix Uptime Kuma Discord Notification Wiring

- [ ] Attach the Discord notification resource to Uptime Kuma monitors.
- [ ] Run focused OpenTofu validation for `infra/uptime-kuma`.
- [ ] Record review and doc impact.

## Plan

Add the existing `uptimekuma_notification.discord` to the Uptime Kuma monitor resources with the provider-supported notification linkage field. Keep the change minimal and verify with focused `tofu validate`; no docs update is expected unless the implementation changes user-facing infra workflow or operator guidance.

# Investigate Uptime Kuma Discord Notification Wiring

- [x] Attach the Discord notification resource to Uptime Kuma monitors.
- [x] Run focused OpenTofu validation for `infra/uptime-kuma`.
- [x] Record review and doc impact.

## Plan

Add the existing `uptimekuma_notification.discord` to the Uptime Kuma monitor
resources with the provider-supported `notification_ids` field. Keep the change
minimal and verify with focused `tofu validate`; no docs update is expected
unless the implementation changes user-facing infra workflow or operator
guidance.

## Review

- Added `locals.default_notification_ids` and wired every
  `uptimekuma_monitor_http` resource in `infra/uptime-kuma/monitors.tf` to the
  existing Discord notification via `notification_ids`.
- Verified the provider schema from
  `breml/terraform-provider-uptimekuma` docs/source; `notification_ids` is the
  supported monitor field for notification linkage.
- `nix develop -c tofu -chdir=infra/uptime-kuma fmt`: passed.
- `TF_DATA_DIR=/private/tmp/uptime-kuma-tfdata nix develop -c tofu -chdir=infra/uptime-kuma validate ...`:
  passed with dummy provider variables and backend disabled via the temporary
  data dir setup.
- `git diff --check`: passed.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because this
  only wires an existing notification resource to existing monitors.

# Add Gitea User ka1ut

- [x] Add `ka1ut` managed Gitea user with email `tka1utjp@gmail.com`.
- [x] Run focused formatting and validation checks for `infra/gitea`.
- [x] Review documentation impact and record results.

## Plan

Modify only `infra/gitea/users.tf`, following the existing local-user pattern:
add a `random_password`, a `gitea_user` with `must_change_password = true`,
and a sensitive output for the generated initial password. Verify with
OpenTofu formatting/validation for `infra/gitea`; no README/AGENTS/CLAUDE/docs
update is expected because this only adds one managed user resource.

## Review

- Added `random_password.ka1ut`, `gitea_user.ka1ut`, and sensitive
  `ka1ut_password` output to `infra/gitea/users.tf`.
- `nix develop -c tofu -chdir=infra/gitea fmt -check`: passed.
- `nix develop -c tofu -chdir=infra/gitea validate`: passed.
- `git diff --check`: passed.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because this
  only adds one managed Gitea user resource.

# Add Quad9 To Tailscale DNS

- [x] Add Quad9 recommended IPv4/IPv6 resolvers to Terraform Tailscale DNS configuration.
- [x] Format and validate the Terraform configuration.
- [x] Review diff and documentation impact.

## Plan

Extend `infra/tailscale/dns.tf` by adding Quad9's recommended recursive DNS
addresses alongside the existing Cloudflare and Google resolvers. Keep the
existing repeated `nameservers` block style.

## Review

- Added Quad9 recommended DNS resolvers to `infra/tailscale/dns.tf`:
  `9.9.9.9`, `149.112.112.112`, `2620:fe::fe`, and `2620:fe::9`.
- `tofu -chdir=infra/tailscale fmt -check`: passed.
- `tofu -chdir=infra/tailscale validate`: blocked because the local
  Tailscale provider is not installed; `tofu init -backend=false` also hit the
  cached S3 backend credential lookup.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed; this is a
  single resolver list update.

# Narrow Infra Deploy Workflow Triggers

- [x] Inspect the current infra deploy workflow path filters.
- [x] Confirm how `infra-ci` is wired into the flake.
- [x] Remove overly broad root flake path triggers from infra deploy.
- [x] Run focused workflow lint/checks.
- [x] Record verification results.

## Plan

Remove `flake.lock` and `flake.nix` from the `pull_request` and `push` path
filters in `.github/workflows/infra-deploy.yaml`. Keep
`modules/flake/per-system/dev-shell.nix` because it directly changes the
`infra-ci` shell used by the workflow. No docs update is expected because this
only narrows CI trigger scope.

## Review

- Removed `flake.lock` and `flake.nix` from the `pull_request` and `push`
  path filters for `.github/workflows/infra-deploy.yaml`.
- Kept `modules/flake/per-system/dev-shell.nix` in the filters because it
  directly changes the workflow's `infra-ci` tool environment.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because this
  only narrows workflow trigger scope.
- `nix run nixpkgs#actionlint -- .github/workflows/infra-deploy.yaml`: passed.
- `nix run nixpkgs#pinact -- run --check`: passed.
- `nix run nixpkgs#zizmor -- --offline .github/workflows/infra-deploy.yaml`:
  passed with no findings.
- `git diff --check`: passed.

# Add Gitea User tak0m0 And Import Existing Users

- [x] Inspect existing Gitea OpenTofu user patterns.
- [x] Confirm existing Gitea users and IDs through the Gitea API.
- [x] Confirm `gitea_user` import IDs are numeric user IDs from provider code.
- [ ] Add `tak0m0` managed user with email `taku.mabuchi@idealike.net`.
- [ ] Add managed resources and import blocks for existing `yuta` and
      `tokuzou0829`.
- [ ] Run format and focused OpenTofu validation checks.
- [ ] Commit, push, and open a draft PR.

## Plan

Modify only `infra/gitea/users.tf`. Add `random_password.tak0m0` and
`gitea_user.tak0m0` using the existing local-user pattern. Add
`gitea_user.yuta` and `gitea_user.tokuzou0829` with current API-observed
attributes, plus `import` blocks using IDs `1` and `2`. Use placeholder
random passwords for imported users only because the provider schema requires
`password`; keep `force_password_change = false` so imported passwords are not
overwritten during normal updates. Verify with `nix fmt`,
`tofu -chdir=infra/gitea fmt -check`, and `tofu -chdir=infra/gitea validate`
with backend disabled if remote backend credentials are unavailable.

# Add LM Studio Provider To OpenCode

- [x] Inspect the existing OpenCode Home Manager module.
- [x] Query the LM Studio API for the actual available model IDs.
- [x] Verify the current generated config lacks the LM Studio provider.
- [x] Add the LM Studio provider to generated `opencode.json`.
- [x] Run formatting and focused Nix evaluation checks.
- [x] Check documentation impact and record results.

## Plan

Update `modules/home/coding-agents/opencode/default.nix`, which owns the
generated `xdg.configFile."opencode/opencode.json"`, to add a single
OpenAI-compatible provider named `lmstudio`. Use the user-provided host
`x870-stell-legend.tail29d068.ts.net` on port `1234` and the model IDs returned
by `GET /v1/models`: `google/gemma-4-26b-a4b-qat` and
`google/gemma-4-26b-a4b`. Exclude the embedding-only model from OpenCode chat
models. Verify by evaluating the generated Darwin Home Manager config text.

## Review

- Queried `http://x870-stell-legend.tail29d068.ts.net:1234/v1/models`; LM
  Studio reported `google/gemma-4-26b-a4b-qat`,
  `google/gemma-4-26b-a4b`, and `text-embedding-nomic-embed-text-v1.5`.
- Added OpenCode provider `lmstudio` with base URL
  `http://x870-stell-legend.tail29d068.ts.net:1234/v1`.
- Added the two chat/tool-capable Gemma models and excluded the embedding-only
  model from OpenCode chat model config.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because this
  only changes generated OpenCode user configuration.
- `nix fmt`: passed, formatted 14 files with 0 changed.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.xdg.configFile."opencode/opencode.json".text'`:
  generated the expected `provider.lmstudio` config.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.home.activationPackage.drvPath'`:
  succeeded with
  `/nix/store/p1x0rddw64jw8gxxsd0hxa2walahcb9y-home-manager-generation.drv`.
- `git diff --check`: passed.

# Investigate Latest CI Failure

- [x] Identify the latest failing GitHub Actions run for the current branch.
- [x] Inspect failed jobs and log snippets.
- [x] Determine the root cause and whether it relates to local changes.
- [x] Record findings and any recommended next step.

## Plan

Use `gh` to inspect the newest Actions runs for the current branch, then drill
into failed jobs/logs for the latest failed run. Stop at root-cause analysis
unless the failure points to a straightforward local fix that the user asks me
to implement.

## Review

- Latest completed failed run is `Infra: OpenTofu` run `27463506744` on PR 879
  at commit `9225a77ad5324c440aaff0b54bd8a9ef064ba02b`.
- `Format` and all `Validate` matrix jobs passed.
- Failed jobs:
  - `Plan (gitea)`: `Error: invalid username, password or token`.
  - `Plan (uptime-kuma)`: `authIncorrectCreds` while creating the
    uptimekuma provider client.
  - `Plan (tailscale)`: S3 backend initialization failed resolving the R2
    endpoint host: `lookup ***: no such host`.
- `gitea` and `uptime-kuma` also warn that `-backend-config` was used without a
  `backend` block, so CI is not using the intended remote S3 state for those
  roots.
- `CI: Pinact check` passed. `CI: Nix build` was still in progress during this
  investigation; the completed failure to address first is `Infra: OpenTofu`.
- Recommended fix: add `backend "s3"` blocks to `infra/gitea` and
  `infra/uptime-kuma`, then verify/update the repository secrets for
  `R2_ENDPOINT`, `GITEA_TOKEN`, `UPTIME_KUMA_USERNAME`, and
  `UPTIME_KUMA_PASSWORD`.

# Fix Infra OpenTofu CI

- [ ] Add missing S3 backend blocks to `infra/gitea` and `infra/uptime-kuma`.
- [ ] Add CI preflight validation for required secrets before expensive
      `tofu init` / `plan` work.
- [ ] Run focused format, validate, and workflow lint checks.
- [ ] Record verification results.

## Plan

Fix the repository-side CI issue by making all OpenTofu roots in the workflow
declare the same S3 backend shape. Add a small preflight step in the workflow
so missing or malformed secrets fail with explicit messages before OpenTofu
emits masked provider/backend errors. Keep provider/resource behavior unchanged;
actual secret rotation remains outside the repository.

# GitHub Actions Tailscale Infra Deploy

- [x] Inspect existing `/infra` OpenTofu layout and GitHub Actions patterns.
- [x] Narrow deploy scope to `infra/gitea` and `infra/uptime-kuma`.
- [x] Confirm S3-compatible backend provider for `homelab-infra-state`.
- [x] Propose a minimal workflow design and get approval before implementation.
- [x] Add the approved workflow and any required docs.
- [x] Run workflow lint/format checks and record results.

## Plan

Add a GitHub Actions workflow for `infra/gitea` and `infra/uptime-kuma`.
Because both roots currently use local ignored state, use a dedicated
S3-compatible bucket named `homelab-infra-state` so GitHub Actions and local
runs operate on the same state. Do not reuse Niks3 because it is cache-specific
storage. Then have a manual `workflow_dispatch` workflow join the tailnet with
`tailscale/github-action`, set up Nix with the existing composite action, and
run `tofu plan` or `tofu apply` for the selected root from the repository dev
shell. Keep strict GitHub permissions and pinned action references to match the
repository's current CI style.

## Review

- Added `.github/workflows/infra-deploy.yaml` with PR `plan`, main-branch
  `apply`, and manual `target` / `mode` inputs for `infra/gitea`,
  `infra/uptime-kuma`, or both.
- The workflow joins Tailscale before running OpenTofu so Uptime Kuma is
  reachable through the tailnet.
- Added partial S3 backend declarations to `infra/gitea` and
  `infra/uptime-kuma`; workflow init supplies R2 backend config for
  `homelab-infra-state`.
- Updated `infra/gitea/README.md` and added `infra/uptime-kuma/README.md` with
  state keys, required secrets, and local run guidance.
- `nix fmt`: passed, formatted 0 changed files.
- `nix develop -c tofu -chdir=infra/gitea fmt -check`: passed.
- `nix develop -c tofu -chdir=infra/uptime-kuma fmt -check`: passed after
  formatting `notifications.tf`.
- `nix develop -c tofu -chdir=infra/gitea validate`: passed.
- `nix develop -c tofu -chdir=infra/uptime-kuma validate`: passed.
- `nix run nixpkgs#actionlint -- .github/workflows/infra-deploy.yaml`: passed.
- `nix run nixpkgs#pinact -- run --check`: passed.
- `nix run nixpkgs#zizmor -- --offline .github/workflows/infra-deploy.yaml`:
  passed with no findings.
- `nix run nixpkgs#ghalint -- run`: still reports pre-existing issues in other
  workflows; the issue initially reported for `infra-deploy.yaml` was fixed by
  moving secrets from job env to step env.
- `git diff --check`: passed.

# Apply PR 878 Gitea User Diff

- [x] Inspect PR metadata and changed files.
- [x] Apply the PR 878 patch to the local checkout.
- [x] Confirm whether `nakasyou` already exists in Gitea with the provided key.
- [x] Apply the Gitea OpenTofu config to create the user if absent.
- [x] Format and validate the Gitea Terraform/OpenTofu config.
- [x] Check docs impact and record results.

## Plan

Apply GitHub PR 878 as-is because it only changes `infra/gitea/users.tf`.
Use the provided Gitea key as an API token to check whether `nakasyou` already
exists. If absent, run the Gitea OpenTofu workflow to create the managed user
and update local state. Verify with formatter, OpenTofu validation, and
whitespace checks.

## Review

- Applied PR 878 patch locally; it only changed `infra/gitea/users.tf`.
- Checked `nakasyou` through the Gitea API using the provided token before
  apply; the user was absent.
- `nix develop --command tofu -chdir=infra/gitea plan -input=false`: planned
  only `random_password.nakasyou` and `gitea_user.nakasyou` additions.
- `nix develop --command tofu -chdir=infra/gitea apply -input=false -auto-approve`:
  succeeded with 2 added, 0 changed, 0 destroyed; `gitea_user.nakasyou` was
  created with id `5`.
- Gitea API check after apply returned `id = 5`, `login = "nakasyou"`, and
  `email = "how@nakasyou.how"`.
- Local OpenTofu state now includes `gitea_user.nakasyou` and
  `random_password.nakasyou`. `infra/gitea/terraform.tfstate` is ignored by
  Git, matching the existing repository setup.
- `nix develop --command tofu -chdir=infra/gitea fmt -check`: passed.
- `nix develop --command tofu -chdir=infra/gitea validate`: passed.
- `git diff --check`: passed.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because the
  existing `infra/gitea/README.md` already documents the token and OpenTofu
  apply workflow.

# Add Darwin Course CLI Environment Variables

- [x] Add `applications/course-cli` Home Manager module.
- [x] Enable it only for the Darwin home configuration.
- [x] Run evaluation/formatting checks and record results.

## Plan

Create a small Home Manager module that exports the `COURSE_`-prefixed NNN
course environment variables through `home.sessionVariables`, then import it
from the Darwin host configuration only.

## Review

- Added `applications/course-cli/default.nix` with the four requested
  `COURSE_`-prefixed environment variables via `home.sessionVariables`.
- Imported `applications/course-cli` only from the Darwin
  `M2-MacBook-Air` Home Manager configuration.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because this
  is a small Darwin-local environment variable module.
- `nix fmt`: passed, formatted 0 changed files.
- `nix eval --json .#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.home.sessionVariables --apply ...`:
  returned the expected `COURSE_API_URL`, `COURSE_PAPI_URL`, `COURSE_WEB_URL`,
  and `COURSE_COOKIE_NAME` values.
- `nix eval --raw .#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.home.activationPackage.drvPath`:
  succeeded with
  `/nix/store/nblpils7fxg8hjs9gq707s8ppbpih70v-home-manager-generation.drv`.
- `git diff --check`: passed.

# Add course-cli Gitea Repository

- [x] Add `course-cli` to the managed private Gitea repositories.
- [x] Format and validate the OpenTofu configuration.
- [x] Check documentation impact and record results.

## Plan

Add a second `gitea_repository` resource under `infra/gitea/repositories.tf`
using the existing `kaikei` pattern: owner `yuta`, name `course-cli`, private
repository, no auto initialization. Keep provider settings unchanged because
`infra/gitea` already targets the private Gitea instance.

## Review

- Added `gitea_repository.course_cli` under `infra/gitea/repositories.tf`.
- The repository is owned by `yuta`, named `course-cli`, marked private, and
  leaves `auto_init = false` to match the existing managed repository pattern.
- Provider configuration was unchanged; `infra/gitea/providers.tf` already
  targets `https://git.yutakobayashi.com`.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed because the
  existing `infra/gitea/README.md` still describes the provider, token
  permissions, and apply flow.
- `nix fmt`: passed, formatted 0 changed files.
- `nix develop --command tofu -chdir=infra/gitea fmt -check`: passed.
- `nix develop --command tofu -chdir=infra/gitea validate`: passed.
- `git diff --check`: passed.

# Add Superpowers To Global Agent Skills

- [x] Add `superpowers` to the shared `agent-skills-nix` sources.
- [x] Enable all `superpowers` skills globally, not only Hermes `brainstorming`.
- [x] Run formatting/evaluation checks and record results.

## Plan

Add `inputs.superpowers` as a source in
`modules/home/coding-agents/agent-skills/default.nix` with `subdir = "skills"`,
then add `superpowers` to `skills.enableAll`. Keep the Hermes-specific
`brainstorming` install unchanged because it is a separate microVM target.

## Review

- Added `superpowers` as a shared `programs.agent-skills.sources` entry using
  `inputs.superpowers` and `subdir = "skills"`.
- Added `superpowers` to `programs.agent-skills.skills.enableAll`, so all
  skills from `obra/superpowers` are installed to the global agent skill
  targets instead of only Hermes' explicit `brainstorming` skill.
- Left `systems/nixos/services/hermes-agent/guest.nix` unchanged; Hermes still
  installs its dedicated `brainstorming` skill bundle.
- README/AGENTS/CLAUDE/docs check: no doc update needed because README already
  lists `obra/superpowers` as an external skill source and names the global
  deploy targets.
- Verified `superpowers` source path and `subdir = "skills"` evaluate for
  `M2-MacBook-Air`: `true`.
- Verified `superpowers` is present in `skills.enableAll` for
  `M2-MacBook-Air`: `true`.
- Verified `superpowers` is present in `skills.enableAll` for `B450M-Pro4`:
  `true`.
- Verified the `superpowers` source contains non-`brainstorming` skills such as
  `systematic-debugging`, `test-driven-development`, and
  `verification-before-completion`.
- `nix fmt`: passed, formatted 0 changed files.
- `nix eval --raw .#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.home.activationPackage.drvPath`:
  succeeded with
  `/nix/store/ynblhgwk3xnc47v85xqk6948ximwnjab-home-manager-generation.drv`.
- `nix eval --raw .#nixosConfigurations.B450M-Pro4.config.home-manager.users.yuta.home.activationPackage.drvPath`:
  succeeded with
  `/nix/store/qysyq9am54br355x7f1cqrkj2dmzks1k-home-manager-generation.drv`.
- `git diff --check`: passed.

# Remove vibe-kanban

- [x] Remove `vibe-kanban` from the shared development Home Manager profile.
- [x] Delete the now-unused `vibe-kanban` module.
- [x] Update docs that list managed AI development tools.
- [x] Run formatting/search/evaluation checks and record results.

## Plan

Remove the package by deleting the development profile import and
`my.programs.vibe-kanban.enable` assignment, then remove the dedicated module
because no other references exist. Update README's managed tools list so docs
match the configuration.

## Review

- Removed the `../../home/coding-agents/vibe-kanban` import and
  `my.programs.vibe-kanban.enable = true` from
  `modules/profiles/home/development.nix`.
- Deleted the now-unused `modules/home/coding-agents/vibe-kanban/default.nix`
  module.
- Updated `README.md` managed AI development tools to remove `vibe-kanban`.
- `rg -n "vibe-kanban|vibekanban" .`: no remaining references.
- `nix fmt`: passed, formatted 0 changed files.
- Darwin check for `M2-MacBook-Air` home packages containing `vibe-kanban`:
  `false`.
- NixOS check for `B450M-Pro4` home packages containing `vibe-kanban`: `false`.
- `git diff --check`: passed.

# Add Chrome GCal URL Opener Extension

- [x] Add `crx-gcal-url-opener` to the managed Chromium/Chrome extension list.
- [x] Run Nix formatting/evaluation checks.
- [x] Review documentation impact and record results.

## Plan

Add the Chrome Web Store extension ID from the provided URL to
`applications/chromium/default.nix` in the existing `programs.chromium.extensions`
list. Verify the module still evaluates and format the Nix file. No README or
docs update is expected because this is a single managed extension addition.

## Review

- Added `pjginhohpenlemfdcjbahjbhnpinfnlm` as `CRX GCal URL Opener` in
  `applications/chromium/default.nix`.
- `nix eval --json .#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.programs.chromium.extensions --apply 'extensions: builtins.any (ext: ext.id == "pjginhohpenlemfdcjbahjbhnpinfnlm") extensions'`:
  returned `true`.
- `nix fmt`: passed, formatted 0 changed files.
- Documentation check: no README/AGENTS/CLAUDE/docs update needed; this only
  adds one managed Chrome extension.

# Add Yamllint Hook

- [x] Add `yamllint` to pre-commit hooks.
- [x] Verify formatting and yamllint hook execution.

## Plan

Add `yamllint` to `modules/flake/per-system/pre-commit.nix` with the requested
secret-file excludes and `document-start` rule override. Keep the change scoped
to pre-commit hook configuration.

## Review

- Added `yamllint.enable = true` with excludes for `secrets/default.yaml` and
  `secrets.yaml`.
- Set `settings.configData` to disable the required document-start rule.
- `nix fmt`: passed, formatted 0 changed files.
- `nix develop -c pre-commit run yamllint --all-files`: passed.
- `git diff --check`: passed.

# Add Pre-Commit Linters

- [x] Add `shellcheck` to pre-commit hooks.
- [x] Add `actionlint` to pre-commit hooks.
- [x] Verify formatting/evaluation.

## Plan

Add both hooks to `modules/flake/per-system/pre-commit.nix` under the existing
`settings.hooks` set. Keep `shellcheck` focused on supported shell scripts by
excluding zsh files and `.envrc`.

## Review

- Added `actionlint.enable = true`.
- Added `shellcheck.enable = true` with `-x`, excluding zsh scripts and
  `.envrc`.
- Removed stale `cachix-auth-token` passing to `setup-nix`; the action already
  configures caches internally with cachix/niks3 and does not accept that input.
- Grouped `_update-flake-reusable.yaml` summary writes into one redirect to
  satisfy actionlint's embedded shellcheck check.
- Updated session-tts bash helpers so shellcheck can follow the shared helper
  and no longer reports unused/missing shell context issues.
- `nix fmt`: passed, formatted 0 changed files.
- `nix develop -c pre-commit run actionlint --all-files`: passed.
- `nix develop -c pre-commit run shellcheck --all-files`: passed.
- `git diff --check`: passed.

# Rename Zed Application Module

- [x] Rename `applications/zed` to `applications/zed-editor`.
- [x] Update Home Manager desktop profile import.
- [x] Verify desktop package evaluation still includes `zed-editor`.

## Plan

Use `git mv` for the application module directory and update the single desktop
profile import. No behavior change; this is a naming cleanup to match the
package name.

## Review

- Renamed `applications/zed/default.nix` to
  `applications/zed-editor/default.nix`.
- Updated `modules/profiles/home/desktop.nix` to import
  `../../../applications/zed-editor`.
- `rg "applications/zed" ...`: only the new `applications/zed-editor` import
  remains.
- UM790-Pro Home Manager package check for `zed-editor`: `true`.
- Darwin Home Manager package check for `zed-editor`: `true`.

# Move s3s To System Services

- [x] Move s3s secrets/templates from Home Manager to the NixOS module.
- [x] Replace `systemd.user` units with system `systemd.services`/`timers`.
- [x] Move runtime config to login-independent state under `/var/lib/s3s`.
- [x] Update docs from `systemctl --user` to system `systemctl`.
- [x] Run focused evaluations/format checks and record results.

## Plan

Run both `s3s.service` and `nxapi-token.service` as system units with
`User = username`, `StateDirectory = "s3s"`, and `WorkingDirectory =
"/var/lib/s3s"`. Keep the config file mutable because `nxapi` refreshes tokens
in place, but initialize it from the sops template only when it is missing so
token refreshes are not overwritten on every service start. Keep Home Manager
only for installing the CLI packages into the user's profile.

## Review

- Moved `sops.secrets` and `sops.templates."s3s-config.txt"` from
  Home Manager scope to NixOS scope.
- Added system `systemd.services.s3s`, `systemd.services.nxapi-token`, and
  `systemd.timers.nxapi-token`.
- Both services run as `User = username` with `StateDirectory = "s3s"` and
  use `/var/lib/s3s/config.txt`.
- `init-s3s-config` seeds the config file only if it is missing, so `nxapi`
  token refreshes are not overwritten on every restart.
- Kept `pkgs.s3s` and `pkgs.nxapi` in the user's Home Manager packages for
  manual CLI use.
- Updated `docs/B450M-Pro4-s3s.md` to use system `systemctl` / `journalctl`
  commands and `/var/lib/s3s/config.txt`.
- `nix eval --json .#nixosConfigurations.B450M-Pro4.config.systemd.services.s3s.serviceConfig`:
  returned `User = "yuta"`, `StateDirectory = "s3s"`, and
  `WorkingDirectory = "/var/lib/s3s"`.
- `nix eval --json .#nixosConfigurations.B450M-Pro4.config.systemd.timers.nxapi-token.timerConfig`:
  returned `OnBootSec = "1min"`, `OnUnitActiveSec = "1h"`, and
  `Persistent = true`.
- `nix eval --raw .#nixosConfigurations.B450M-Pro4.config.system.build.toplevel.drvPath`:
  succeeded with
  `/nix/store/q35sdspgmm5lc0ha9awyg4kssdmck4fv-nixos-system-B450M-Pro4-26.11.20260606.7de43b9.drv`.
- `nix eval --json .#nixosConfigurations.B450M-Pro4.config.home-manager.users.yuta.systemd.user.services --apply 'services: builtins.hasAttr "s3s" services || builtins.hasAttr "nxapi-token" services'`:
  returned `false`.
- `nix eval --json .#nixosConfigurations.B450M-Pro4.config.systemd.services --apply 'services: { hasS3s = builtins.hasAttr "s3s" services; hasNxapiToken = builtins.hasAttr "nxapi-token" services; }'`:
  returned both as `true`.
- `nix fmt`: passed, formatted 1 changed file.
- `git diff --check`: passed.

# Move s3s Package To nur-packages

- [x] Add `s3s` package definition to `yutakobayashidev/nur-packages`.
- [x] Export `s3s` from the NUR package set/overlay.
- [x] Replace the local `mkDerivation` in dotnix with `pkgs.s3s`.
- [x] Update related docs to say the package lives in nur-packages.
- [x] Run focused Nix evaluation/format checks and record results.

## Plan

Move the existing local `systems/nixos/services/s3s/default.nix` derivation
unchanged into `../nur-packages/pkgs/s3s/default.nix`, export it from
`../nur-packages/default.nix`, then simplify the dotnix service module to use
`pkgs.s3s`. Keep the service behavior and token/config logic unchanged.

## Review

- Added `../nur-packages/pkgs/s3s/default.nix` with the package definition that
  was previously local to dotnix.
- Exported `s3s` from `../nur-packages/default.nix`; note that the file already
  had unrelated local changes before this task.
- Removed the local `pkgs.stdenv.mkDerivation` from
  `systems/nixos/services/s3s/default.nix` and switched the service/package
  references to `pkgs.s3s`.
- Updated `docs/B450M-Pro4-s3s.md` to document `pkgs.s3s` as coming from the
  `nur-packages` flake input.
- `nix eval --override-input nur-packages path:../nur-packages --raw .#nixosConfigurations.B450M-Pro4.config.home-manager.users.yuta.home.packages --apply 'packages: builtins.toString (builtins.any (p: (p.pname or p.name or "") == "s3s") packages)'`:
  returned `1`.
- `nix eval --override-input nur-packages path:../nur-packages --raw .#nixosConfigurations.B450M-Pro4.config.home-manager.users.yuta.systemd.user.services.s3s.Service.ExecStart --apply builtins.head`:
  returned an `s3s-0.7.0-unstable-2025-08-19/bin/s3s -M 300 -r` store path.
- `nix fmt` in dotnix: passed, formatted 0 changed files.
- `nix run nixpkgs#nixfmt-rfc-style -- ../nur-packages/default.nix ../nur-packages/pkgs/s3s/default.nix`:
  passed.
- `git diff --check` in dotnix and nur-packages: passed.
- Direct nur-packages flake evals for `legacyPackages.*.s3s.meta.mainProgram`
  stalled while copying/evaluating nixpkgs source and were stopped; the dotnix
  override-input checks above verified the actual integration path.

# Permit Checkov Insecure Transitive Dependency

- [x] Locate the CI failure source in the default devShell.
- [x] Confirm `checkov` is not referenced by repo workflows or docs.
- [x] Keep `checkov` in the devShell package list.
- [x] Permit only `python3.13-ecdsa-0.19.2` in shared nixpkgs config.
- [ ] Run devShell and diff checks.
- [ ] Commit and push the CI fix.

## Plan

Keep `localPkgs.checkov` in `modules/flake/per-system/dev-shell.nix` and add
`python3.13-ecdsa-0.19.2` to `permittedInsecurePackages` in the shared `mkPkgs`
import. This keeps the exception narrow and avoids enabling all insecure
packages.

## Review

- Pending.

# Add Zed Editor To Applications

- [x] Confirm the nixpkgs package is available for Darwin and NixOS configs.
- [x] Add a minimal `applications/zed` Home Manager module.
- [x] Import Zed from the shared desktop profile.
- [x] Fix CI hostname typo for `X870-Steel-Legend-WiFi`.
- [x] Run formatting/evaluation/diff checks.
- [x] Review documentation impact and record results.

## Plan

Add Zed as a standalone `applications/zed` module that installs
`pkgs.zed-editor`, then import it from `modules/profiles/home/desktop.nix` with
the other GUI applications. Keep it package-only unless a config need appears.
Also fix the CI hostname typo surfaced by the interrupted build log.

## Review

- Added `applications/zed/default.nix` with `pkgs.zed-editor`.
- Imported `applications/zed` from `modules/profiles/home/desktop.nix`.
- Fixed CI references from `X870-Stell-Legend-WiFi` to
  `X870-Steel-Legend-WiFi`.
- `rg "X870-Stell" -n .`: no matches.
- `nix eval '.#nixosConfigurations' --apply 'x: builtins.attrNames x'`:
  includes `X870-Steel-Legend-WiFi`.
- `nix eval --raw '.#nixosConfigurations.X870-Steel-Legend-WiFi.config.networking.hostName'`:
  returned `X870-Steel-Legend-WiFi`.
- Darwin Home Manager package check for `zed-editor`: `true`.
- UM790-Pro Home Manager package check for `zed-editor`: `true`.
- `nix eval --raw '.#nixosConfigurations.X870-Steel-Legend-WiFi.config.system.build.toplevel.drvPath'`:
  succeeded with
  `/nix/store/dz5vk7vmr8cbraav2mm376pp96d226im-nixos-system-X870-Steel-Legend-WiFi-26.11.20260606.7de43b9.drv`.
- `nix fmt`: passed with `0 changed`.
- `git diff --check`: passed.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this only adds one GUI app module and fixes a CI
  hostname typo.

# Move Modrinth App To Homebrew

- [x] Remove Modrinth App from Home Manager package evaluation.
- [x] Add Modrinth App to the shared macOS Homebrew casks.
- [x] Verify the Darwin configuration references the Homebrew cask and no longer builds the nixpkgs package.
- [x] Add the requested NixOS gcr SSH agent disablement after `programs.ssh.startAgent`.
- [x] Run formatting/evaluation/diff checks and record results.

## Plan

Move only `modrinth-app`: delete the nixpkgs package from
`homes/darwin/desktop.nix` and add the Homebrew cask token to
`systems/darwin/homebrew.nix` under the existing app grouping. Also add the
requested NixOS option directly after `programs.ssh.startAgent = true;`.

## Review

- Removed `modrinth-app` from `homes/darwin/desktop.nix`.
- Added Homebrew cask token `modrinth` to `systems/darwin/homebrew.nix`.
- Confirmed current Homebrew Formulae lists `brew install --cask modrinth`.
- Added `services.gnome.gcr-ssh-agent.enable = false;` immediately after
  `programs.ssh.startAgent = true;` in `systems/nixos/common.nix`.
- `nix eval --json '.#darwinConfigurations.M2-MacBook-Air.config.homebrew.casks'`:
  succeeded and includes `cask "modrinth"`.
- `nix eval --json '.#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.home.packages' --apply 'packages: builtins.any (p: (p.pname or p.name or "") == "modrinth-app") packages'`:
  returned `false`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`:
  succeeded with
  `/nix/store/k80nns9j8jvcpmm3jfmsgfmb159l0brp-darwin-system-26.11.f8531f9.drv`.
- `nix eval --raw '.#nixosConfigurations.B450M-Pro4.config.system.build.toplevel.drvPath'`:
  succeeded with
  `/nix/store/5gzy2a8z8y735bcbqkm9ii3672k4r74y-nixos-system-B450M-Pro4-26.11.20260606.7de43b9.drv`.
- `nix fmt`: passed with `0 changed`.
- `git diff --check`: passed.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this only moves one app between existing package
  managers and adds one NixOS option.

# Remove VS Code And Cursor Editor Config

- [x] Confirm all VS Code/Cursor editor declarations.
- [x] Remove Cursor editor Home Manager import and module files.
- [x] Remove VS Code from macOS Homebrew casks.
- [x] Verify no VS Code/Cursor editor config remains while keeping Cursor Agent.
- [x] Run formatting/evaluation checks.
- [x] Record review notes.

## Plan

Keep Cursor Agent intact. Remove only the GUI/editor configuration surface:
`applications/cursor`, its desktop profile import, and the macOS
`visual-studio-code` Homebrew cask. Do not remove Neovim language server
packages such as `vscode-langservers-extracted`, because those are not VS Code
or Cursor editor configuration.

## Review

- Removed the Home Manager desktop import for `applications/cursor`.
- Deleted the Cursor editor module files under `applications/cursor/`.
- Removed the macOS Homebrew `visual-studio-code` cask.
- Removed the Claude notification hook branch that explicitly activated the
  Cursor GUI app.
- Kept Cursor Agent intact:
  `modules/home/coding-agents/cursor-agent/default.nix`,
  `my.programs.cursor-agent.enable = true`, and the `ca="cursor-agent"` alias
  still remain.
- `rg` check: no remaining declarations for `applications/cursor`,
  `programs.vscode`, `code-cursor`, `visual-studio-code`,
  `vscode-file-nesting-config`, Cursor GUI activation, or
  `VSCODE_GIT_ASKPASS_MAIN`.
- `nix eval --json '.#darwinConfigurations.M2-MacBook-Air.config.homebrew.casks'`:
  succeeded; `visual-studio-code` is absent.
- `git diff --check`: passed.
- `nix fmt`: failed on an existing malformed
  `.github/workflows/nix-build.yaml` list indentation issue, unrelated to this
  change. It also briefly formatted `homes/android/Galaxy-S23FE/default.nix`;
  that unrelated formatter change was reverted.
- `nix eval --impure --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`:
  failed on existing `../../../../applications/...` imports resolving as an
  invalid `/nix/store/applications/...` path. The failure points at existing
  profile imports such as `modules/profiles/home/terminal.nix`, not at the
  removed Cursor module.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this removes editor configuration without changing
  documented architecture or commands.

# Fix Formatter And Darwin Eval Blockers

- [x] Fix malformed GitHub Actions YAML lists.
- [x] Fix Home Manager profile imports that overshoot the repository root.
- [x] Fix the session TTS overlay source path that overshot the repository root.
- [x] Run `nix fmt`.
- [x] Re-run Darwin toplevel evaluation.
- [x] Record review notes.

## Plan

Repair only the blockers surfaced during verification: normalize the Nix-related
path lists in `.github/workflows/nix-build.yaml`, and change Home Manager
profile imports from `../../../../applications/...` to
`../../../applications/...`. Keep the prior VS Code/Cursor deletion intact and
leave Cursor Agent unchanged. If the same root-overshoot pattern appears in
adjacent repo-local imports during evaluation, fix that as part of this blocker
cleanup.

## Review

- `.github/workflows/nix-build.yaml`: normalized the malformed path lists in
  both `push.paths` and `dorny/paths-filter` config.
- `modules/profiles/home/{cli,desktop,development,terminal}.nix`: changed
  repo-local application imports from `../../../../applications/...` to
  `../../../applications/...`.
- `overlays/session-tts-codex.nix`: changed the session TTS source path from
  `../../codex/session-tts/python` to `../codex/session-tts/python`.
- `nix fmt`: passed.
- `git diff --check`: passed.
- `rg` check: no remaining `../../../../applications` or
  `../../codex/session-tts/python` root-overshoot imports.
- `nix eval --impure --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`:
  passed with
  `/nix/store/q6170adn5nbjrhlbvp39dsysc3a3clmf-darwin-system-26.11.f8531f9.drv`.

# Replace Managed Gitea Repository With Existing Kaikei

- [x] Confirm the current Gitea OpenTofu resource model and provider fields.
- [x] Replace the managed `beancount` repository definition with `kaikei`.
- [x] Document importing the existing Gitea repository into OpenTofu state.
- [x] Run formatting and validation checks.
- [x] Review docs impact and record results.

## Plan

Keep the change scoped to `infra/gitea`. Replace the managed repository
definition from `beancount` to the already-existing Gitea repository `kaikei`,
then document the one-time `tofu import` command needed to attach that existing
remote resource to local state.

## Review

- `infra/gitea/repositories.tf`: `gitea_repository.beancount` replaced by
  `gitea_repository.kaikei` with the same simple repository settings.
- `infra/gitea/README.md`: added the one-time state import command before
  `apply`.
- `z-ai/lessons.md`: recorded that existing infrastructure "import" means state
  import unless the user explicitly asks for provider-level migration.
- `nix develop -c tofu -chdir=infra/gitea fmt -check`: passed.
- `nix develop -c tofu -chdir=infra/gitea validate`: passed. It printed a Nix
  eval-cache SQLite busy warning, but OpenTofu reported the configuration is
  valid.

# Add Prism Launcher To macOS Via Nixpkgs

- [x] Confirm the nixpkgs package is available for the Darwin configuration.
- [x] Add Prism Launcher to the macOS Home Manager package list.
- [x] Verify the Darwin configuration includes the new package.
- [x] Run formatting / diff checks.
- [x] Review documentation impact and record results.

## Plan

Add `pkgs.prismlauncher` to `homes/darwin/desktop.nix` under the existing
macOS nixpkgs app grouping. Keep the change narrow and verify via
`darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.home.packages`
plus standard diff checks.

## Review

- `pkgs.prismlauncher.pname`: evaluated to `prismlauncher`.
- `pkgs.prismlauncher.version`: evaluated to `11.0.2`.
- `home-manager.users.yuta.home.packages` includes a package with `pname = "prismlauncher"`: `true`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`: succeeded with `/nix/store/zk9hlssqwhaxy4bmq9qyl19w68ijwwd7-darwin-system-26.05.56c666e.drv`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- `nix run .#switch`: attempted, but this non-interactive session cannot provide the required `sudo` password (`sudo: a terminal is required to read the password`).
- Documentation check: no updates needed for `README.md`, `AGENTS.md`, `CLAUDE.md`, or `docs/`; this only adds one macOS GUI package through the existing Home Manager package list.

# Codex Writable Roots TTS Diagnosis

- [ ] Inspect the Nix source that generates Codex `config.toml`.
- [ ] Check current official Codex docs/manual for workspace-write writable root syntax and behavior.
- [ ] Compare generated config intent with this session's observed sandbox context.
- [ ] Identify the likely cause and minimal fix, if any.
- [ ] Run targeted verification if a code/config change is needed.
- [ ] Record review notes.

## Plan

Treat `nix/modules/home/coding-agents/codex/` as the source of truth, not the
generated `~/.config/codex/config.toml`. Use the official Codex manual to verify
the current configuration schema, then decide whether the issue is a Nix
generation bug, a Codex CLI interpretation issue, or a current-session policy
that is overriding the intended writable roots.

## Review

- Pending.

# Codex Session TTS Hook JSON Schema Fix

- [x] Reproduce the invalid hook JSON output with isolated hook inputs.
- [x] Check the current official Codex hooks documentation.
- [x] Identify the invalid hook JSON schema for `SessionStart` and `UserPromptSubmit`.
- [x] Patch the minimal TTS plugin source.
- [x] Verify both hooks emit the documented hook-specific JSON shape.
- [x] Run formatting/diff checks and review documentation impact.

## Plan

Use the current official Codex hooks documentation as the contract. Keep hook
stdout reserved for valid hook responses, and emit event-specific context under
`hookSpecificOutput` with the matching `hookEventName`.

## Review

- Official source checked: `https://developers.openai.com/codex/hooks.md`.
- Root cause: `SessionStart` and `UserPromptSubmit` JSON context must use
  `hookSpecificOutput.hookEventName` plus
  `hookSpecificOutput.additionalContext`. The previous top-level
  `additionalContext` object was invalid for these events.
- Secondary hardening: `SessionStart` startup playback remains best-effort with
  stdout/stderr suppressed so speech output cannot pollute hook stdout.
- Fix: `SessionStart` now emits the documented `hookSpecificOutput` shape.
- Fix: `remind-say.sh` now emits the documented `hookSpecificOutput` shape for
  `UserPromptSubmit` and `SubagentStart`.
- Installed plugin cache refreshed with `codex plugin remove session-tts@personal`
  and `codex plugin add session-tts@personal`.
- Verification:
  - Isolated source hook tests: `SessionStart`, active `UserPromptSubmit`, and
    `SubagentStart` all emitted `hookSpecificOutput` with a string
    `additionalContext`.
  - Cached installed hook tests: `SessionStart` and active `UserPromptSubmit`
    emitted the documented `hookSpecificOutput` shape.
  - Simulated playback adapter stdout/stderr and nonzero exit still did not
    pollute or fail `SessionStart`.
  - `bash -n` passed for changed shell scripts.
  - Final formatting/diff checks pending after this correction.

# B450M SOPS Key Rotation

- [x] Confirm old B450M age key is unrecoverable from local logs/tmp.
- [x] Generate a new B450M age key outside the repo and outside tmp.
- [x] Replace the B450M recipient in `.sops.yaml`.
- [x] Re-key shared secrets that are decryptable from this Mac.
- [x] Recreate B450M-only secrets with fresh values or known replacement values.
- [x] Add durable agent instructions against writing secrets to tmp.
- [x] Update lessons with the tmp-secret failure pattern.
- [x] Verify sops metadata and Nix formatting/evaluation enough for this change.
- [x] Record review notes.

## Plan

Rotate the lost B450M age recipient by generating a new persistent age identity at a repo-external path, updating `.sops.yaml`, and re-encrypting affected files. Files encrypted only to the lost B450M recipient cannot be decrypted, so recreate those secrets instead of trying to recover them.

## Review

### Verification Results

- **sops metadata**: 全ファイルが新しいB450M recipient (`age1ahvwx3a7z...h23jle`) で暗号化されていることを確認。
  - `secrets/default.yaml`: UM790 + B450M-new + M2-MacBook-Air の3recipient ✓
  - `systems/nixos/services/grafana/secrets.yaml`: B450M-new のみ ✓
  - `systems/nixos/services/nextcloud/secrets/default.yaml`: B450M-new のみ ✓
  - `systems/nixos/services/oura-metrics/secrets.yaml`: B450M-new のみ ✓
- **復号確認**: `secrets/default.yaml` は Mac の age 鍵で復号可能。B450M-only の3ファイルは Mac から復号不可（正しい動作）。
- **nix eval**: `B450M-Pro4` の評価成功 (`/nix/store/3dh1h58x...-nixos-system-B450M-Pro4-26.05.20260521.a81eafb.drv`)。
- **nix fmt**: フォーマット変更なし（0 changed）。

### nix-anywhere 時の注意点

- `sops.age.generateKey = true` により、`keyFile` が存在しない場合ランダムな鍵が自動生成される。これは `.sops.yaml` の recipient と一致しないため、全 secrets 復号が失敗する。
- `sshKeyPaths` は SSH ホスト鍵から age 鍵を派生させるが、この SSH 鍵の age 公開鍵は `.sops.yaml` に登録されていないためフォールバックとして機能しない。
- **対策**: `nix-anywhere` 前に `b450m-pro4.keys.txt` をターゲットの `/home/yuta/.config/sops/age/keys.txt` に配置する手順を `docs/B450M-Pro4.md` に追加した。

### 変更ファイル一覧

| ファイル                                                | 変更内容                                                    |
| ------------------------------------------------------- | ----------------------------------------------------------- |
| `.sops.yaml`                                            | B450M recipient を新鍵に差し替え                            |
| `secrets/default.yaml`                                  | 3 recipient で再暗号化                                      |
| `systems/nixos/services/grafana/secrets.yaml`           | B450M 新鍵で再暗号化（値は再生成）                          |
| `systems/nixos/services/nextcloud/secrets/default.yaml` | B450M 新鍵で再暗号化（値は再生成）                          |
| `systems/nixos/services/oura-metrics/secrets.yaml`      | B450M 新鍵で再暗号化（値は再入力）                          |
| `AGENTS.md`                                             | Secret Handling セクション追加（tmpに秘密鍵を書かない指示） |
| `docs/B450M-Pro4.md`                                    | nix-anywhere 前に age 鍵配置手順を追加                      |
| `z-ai/lessons.md`                                       | tmp-secret failure pattern を記録                           |

# Twitter API Safe Relay Skill

- [x] Confirm the upstream skill layout and existing `agent-skills-nix` pattern.
- [x] Add the upstream GitHub flake input.
- [x] Enable the upstream `twitter-api-replay` skill through `agent-skills-nix`.
- [x] Update the external skill source documentation.
- [x] Update `flake.lock`.
- [x] Run formatting and Nix evaluation checks.
- [x] Record review notes.

## Plan

Add `fa0311/twitter_api_safe_relay_skills` as a non-flake input and enable its `skills/` directory through the existing Home Manager `agent-skills-nix` module.

## Review

- Upstream layout: confirmed `skills/twitter-api-replay/` is the source of truth.
- `flake.lock`: pinned `fa0311/twitter_api_safe_relay_skills` at `19f55e7e81fe588ed47554afa8b2419775335604`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- `nix eval --json '.#darwinConfigurations.M2-MacBook-Air.config.home-manager.users.yuta.programs.agent-skills.skills.enableAll'`: includes `twitter-api-safe-relay`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`: succeeded with `/nix/store/39idl965lsig8cx9gicww00byhzjj6qp-darwin-system-26.05.56c666e.drv`.

# Homebrew Cleanup Activation Fix

- [x] Confirm the generated Homebrew activation command fails because cleanup lacks explicit confirmation.
- [x] Check the nix-darwin Homebrew activation options for a native flag hook.
- [x] Add the narrow `--force-cleanup` flag to Homebrew activation.
- [x] Evaluate the generated activation command.
- [x] Run formatting and diff checks.
- [x] Record review notes.

## Plan

Keep `cleanup = "uninstall"` and pass Homebrew's `--force-cleanup` flag through
`homebrew.onActivation.extraFlags`. This preserves declarative cleanup without
using the broader `--force` behavior.

## Review

- `nix eval --json '.#darwinConfigurations.M2-MacBook-Air.config.homebrew.onActivation.extraFlags'`: returned `["--force-cleanup"]`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.activationScripts.homebrew.text'`: generated `brew bundle ... --cleanup --force-cleanup`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`, `CLAUDE.md`, or `docs/`; this only adjusts an existing Homebrew activation flag.

# Home Manager And Stable Nixpkgs Upgrade

- [x] Confirm the root Home Manager input and current lock state.
- [x] Update the root `home-manager` flake input.
- [x] Update the root `nixpkgs-stable` flake input.
- [x] Evaluate the affected Home Manager-backed configuration and confirm the release mismatch warning is gone.
- [x] Run diff checks and record review notes.

## Plan

Update the root `home-manager` and `nixpkgs-stable` lock nodes while preserving
their existing input definitions. Verify with a Darwin configuration
evaluation, then inspect the lock diff and document whether user-facing docs
need changes.

## Review

- `home-manager`: updated from `61e2c9659324181e0f0ed911958c536333b1d4f6`
  to `7d8127d308c3fb9664f7e643eec944be74ebb37d`.
- `nixpkgs-stable`: update command completed without a lock diff because the
  existing revision `25f538306313eae3927264466c70d7001dcea1df` was already current.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`:
  succeeded with `/nix/store/w6prrdxlnp4q55d7ih4s1kpi6z91avxk-darwin-system-26.05.56c666e.drv`.
  The Home Manager release mismatch warning is gone.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this only refreshes the Home Manager lock revision.

# Nixpkgs Stable 26.05 Upgrade

- [x] Confirm the official `nixos-26.05` branch exists upstream.
- [x] Change the root `nixpkgs-stable` input from `nixos-25.11` to `nixos-26.05`.
- [x] Refresh the root `nixpkgs-stable` lock node.
- [x] Evaluate the Darwin configuration and run diff checks.
- [x] Review documentation impact and record results.

## Plan

Move the stable fallback input to the official Nixpkgs `nixos-26.05` release
branch, refresh only that lock node, and evaluate the Darwin configuration.
Keep existing `stateVersion` declarations unchanged because they are migration
compatibility settings, not package channel selectors.

## Review

- Official upstream check: `refs/heads/nixos-26.05` exists at
  `b51242d7d43689db2f3be91bd05d5b24fbb469c4`.
- `nixpkgs-stable`: moved from the `nixos-25.11` branch at `25f5383...` to the
  `nixos-26.05` branch at `b51242d...`.
- `nix eval --raw '.#darwinConfigurations.M2-MacBook-Air.config.system.build.toplevel.drvPath'`:
  succeeded with `/nix/store/ippq71jxdl1pqbai0m1ina6822iphkvn-darwin-system-26.05.56c666e.drv`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; the stable fallback architecture and commands are
  unchanged.

# Darwin Tailscale DNS Fix

- [x] Confirm the rebuild failure is caused by DNS resolution rather than MAS app IDs.
- [x] Inspect nix-darwin's Tailscale DNS behavior and the active macOS resolver state.
- [x] Remove the fragile global Tailscale DNS override while preserving MagicDNS.
- [x] Configure B450M-Pro4 to use only its local CoreDNS resolver.
- [x] Evaluate the affected configurations and run diff checks.
- [x] Review documentation impact and record results.

## Plan

Remove `services.tailscale.overrideLocalDns = true` from the Darwin common
configuration. The nix-darwin Tailscale module already installs a split DNS
resolver for `ts.net`, so normal Wi-Fi DNS can handle public domains without
giving up MagicDNS. Configure B450M-Pro4 to use only `127.0.0.1` so CoreDNS is
the single resolver and DNS routing failures are visible instead of silently
bypassed.

## Review

- Darwin `networking.dns`: evaluates to `[]`, restoring DHCP-provided DNS.
- Darwin `environment.etc."resolver/ts.net".text`: remains
  `nameserver 100.100.100.100`, preserving MagicDNS split DNS.
- B450M-Pro4 `networking.nameservers`: evaluates to `["127.0.0.1"]`.
- Darwin toplevel evaluation: succeeded with
  `/nix/store/aniq3cgzddhz2xmf5r62ay714c3xpddw-darwin-system-26.05.56c666e.drv`.
- B450M-Pro4 toplevel evaluation: succeeded with
  `/nix/store/2840bh1gbjfw7gknbb0daw5sam912zvv-nixos-system-B450M-Pro4-26.11.20260529.e9a7635.drv`.
- `nix fmt`: completed with `0 changed`.
- `git diff --check`: completed without errors.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; existing commands and architecture are unchanged.

# Add Agent Skill Tools

- [x] Confirm package attribute names for `skill-scanner`, `skillspector`, and `magika`.
- [x] Add `skill-scanner` and `skillspector` from local/NUR packages to the default dev shell.
- [x] Add `magika` from nixpkgs to shared misc home packages.
- [x] Run formatting/evaluation checks and review documentation impact.

## Plan

Keep this as a package-list-only change. Use the existing `localPkgs` dev shell
pattern for tools that come from `nur-packages`, and use the normal `pkgs`
package list for `magika`.

## Review

- Added `localPkgs.skill-scanner` and `localPkgs.skillspector` to
  `devShells.default`.
- Added nixpkgs `magika` to the shared misc Home Manager package list.
- Updated the `nur-packages` flake input from
  `4940293ed473fa365b7390c12e75b15814fac738` to
  `c9a817ec2e5e7f02e6819b71e7bd02cf778e7590`, which contains the new package
  attributes.
- Verified `skill-scanner-env`, `skillspector-env`, and `magika-1.0.2`
  attribute evaluation.
- `nix fmt`: passed with `0 changed`.
- `git diff --check`: passed.
- Darwin toplevel evaluation for `M2-MacBook-Air`: succeeded with
  `/nix/store/rfrkfx82x3x9bplnzly6mhmmb5f9dzgg-darwin-system-26.11.6a77112`.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this only changes installed package lists and the
  locked NUR package revision.

# Darwin MAS Activation Workaround

- [x] Confirm the Homebrew Bundle failure matches the upstream nix-homebrew issue.
- [x] Disable Homebrew auto-update during nix-darwin activation.
- [x] Link the upstream issue next to the workaround.
- [x] Restore Spotlight indexing for the macOS Data volume.
- [x] Confirm `mas list` detects Keynote, Numbers, and Pages again.
- [ ] Evaluate the generated Homebrew activation script and run diff checks.
- [ ] Review documentation impact and record results.

## Plan

Apply the upstream workaround from
https://github.com/zhaofengli/nix-homebrew/issues/131 by disabling Homebrew
auto-update during nix-darwin activation. Keep normal manual Homebrew updates
unchanged. Restore the disabled Spotlight index on the macOS Data volume so
`mas` can detect already installed App Store applications.

## Review

- Pending final verification.

# Codex Session TTS Plugin Detail Fix

- [x] Reproduce the personal marketplace plugin path mismatch.
- [x] Validate the existing plugin against the current Codex plugin contract.
- [x] Move the plugin symlink to the personal marketplace source path.
- [x] Update the marketplace source descriptor and plugin metadata.
- [x] Move the internal say adapter out of the public skills directory.
- [ ] Validate the plugin and reinstall it through Home Manager.
- [ ] Confirm Codex can read plugin details and record review notes.

## Plan

Align `session-tts` with the current personal marketplace layout:
`~/.agents/plugins/marketplace.json` points to `./plugins/session-tts`, which
resolves to `~/plugins/session-tts`. Keep hook discovery under `hooks/`, expose
only real skills under `skills/`, then validate and reinstall the local plugin.

## Review

- Pending final verification.

# Codex Session TTS Thread ID Fix

- [x] Reproduce the missing session identifier error from the TTS skill.
- [x] Inspect the Bash tool environment for the identifier Codex exposes.
- [x] Replace the incorrect `CODEX_SESSION_ID` references with `CODEX_THREAD_ID`.
- [x] Verify session-local `status`, `off`, and `on` behavior.
- [x] Run diff checks and review documentation impact.

## Plan

Use Codex's exported `CODEX_THREAD_ID` for Bash tool calls. Hook payloads keep
using their JSON `session_id` field because Codex supplies that identifier on
stdin for hook invocations.

## Review

- Root cause: Bash tool calls export `CODEX_THREAD_ID`, not
  `CODEX_SESSION_ID`. Hook payloads still provide JSON `session_id`.
- Updated `skills/tts/tts.sh`, `scripts/say.sh`, and the TTS skill
  documentation to use `CODEX_THREAD_ID`.
- Reinstalled `session-tts@personal` with `codex plugin remove` followed by
  `codex plugin add`, refreshing the user cache.
- Cached skill verification: `Codex TTS (this session): ON`.
- Shell adapter verification: simulated `SessionStart`, then confirmed
  `status`, `off`, `status`, `on`, `status`, and `say.sh` behavior.
- `bash -n`, `git diff --check`, and `git diff --cached --check`: passed.
- Darwin toplevel evaluation: succeeded with
  `/nix/store/cm15rvb0ifpblnpmk18b5z7qd8lagl47-darwin-system-26.05.56c666e.drv`.
- Python suite: `50 passed, 5 failed`. The existing chunking failures are
  unrelated to this shell adapter fix.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; the affected TTS skill documentation was updated.

# Codex Session TTS Chunking Fix

- [x] Reproduce the five Python chunking test failures.
- [x] Identify sentence recombination and whitespace removal as the causes.
- [x] Keep sentence chunks separate unless a single sentence needs forced splitting.
- [x] Preserve paragraph separators while ignoring whitespace-only input.
- [x] Run the Python suite and diff checks.
- [x] Evaluate the Darwin configuration and record final results.

## Plan

Keep `_split_paragraph()` focused on sentence boundaries and forced splitting
of oversized sentences. Preserve paragraph separators in `split_into_chunks()`
so concatenating chunks reconstructs the cleaned input.

## Review

- Root cause: `_split_paragraph()` split on sentence punctuation and then
  recombined adjacent sentences whenever they fit under the size limit. Its
  regex also discarded whitespace after punctuation, while
  `split_into_chunks()` discarded paragraph separators with `strip()`.
- `_split_paragraph()` now returns sentence chunks directly and only invokes
  `_force_split()` for an oversized sentence.
- `split_into_chunks()` now carries paragraph separators into the following
  paragraph while still ignoring whitespace-only input.
- Python suite: `55 passed`.
- `bash -n`, `git diff --check`, and `git diff --cached --check`: passed.
- Darwin toplevel evaluation: succeeded with
  `/nix/store/21cw3hy7r1xplh40f15z97hg4p0s76ab-darwin-system-26.05.56c666e.drv`.
- Documentation check: no updates needed for `README.md`, `AGENTS.md`,
  `CLAUDE.md`, or `docs/`; this is an internal chunking behavior correction.

# Add mpv And ffplay

- [ ] Add `mpv` and `ffplay` next to `ffmpeg` in the shared misc package list.
- [ ] Run a focused Nix evaluation/formatting check for the touched module.
- [ ] Record review and documentation impact.

## Plan

Update only `applications/misc/default.nix`, keeping the existing package order
and placing `mpv` and `ffplay` adjacent to `ffmpeg` as requested. Verify with a
focused Nix formatting check plus `git diff --check`; no docs update is
expected unless this package-list change requires user-facing setup
documentation.
