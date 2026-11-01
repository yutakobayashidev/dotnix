# Agent skill sources

Skill-only repositories use the [upstream source registry](https://github.com/Kyure-A/agent-skills-nix/tree/dc122af897ab9a685c20ae54c639021619dbbb52/examples/source-registry).

- `registry/sources/*.nix` declares each repository, branch, and discovery settings.
- `registry/sources.lock.json` snapshots those manifests and pins revisions and hashes.
- `lib/skill-sources.nix` loads the registry for Home Manager, the development shell, and Hermes.
- Feature modules retain skill selection, package dependencies, and content transformations.

Package-providing repositories continue to use flake inputs so their skills and
packages share a revision. Repository-local skills continue to use local paths.

## Package and skill features

Tool-specific Home Manager features own their package, skill source, selection,
and command transforms together under `my.programs.<tool>.enable`, following the
Oracle pattern. Profiles enable these features rather than installing the same
packages separately:

- Media: Bird, Discrawl, edcb-tools, Obsidian, and webforai.
- Development: ast-grep, before-and-after, difit, and repiq, alongside the existing
  Oracle, agent-browser, Babashka, and other tool features.

The central `agent-skills` feature keeps shared deployment/targets and general
skills that do not belong to a dedicated application. Enable
`my.programs.agent-skills.enable` to deploy selected skills. Disabling a tool
feature removes its package and dedicated upstream skill selection; disabling
skill integration does not remove enabled tools. The `local` source
(`yutakobayashidev/skills`) is an exception: all its skills are enabled centrally,
including newly added skills after refreshing the source lock. Tool features
still supply package dependencies and transforms for their local skills when
enabled, but disabling a tool does not hide those local instructions. Local
skills do not automatically install every tool they describe. A development-only
home does not receive media applications or their separate upstream skills unless
it enables those features too.

For example, a Home Manager configuration can select a tool independently:

```nix
my.programs.agent-skills.enable = true;
my.programs.webforai.enable = true;
my.programs.repiq.enable = true;
```

Obsidian owns the five selected Obsidian-source skills; defuddle is not selected.
Discrawl's CLI/skill feature is independent of its user services. Enabling its
services enables the feature by default, and explicitly disabling the feature
while keeping services enabled is rejected. Existing service settings are retained.
Hermes has a separate service-local skill bundle and continues using the shared
webforai transform.

## Selecting general skills

Edit `selectedSkillPaths` in
`modules/features/super-intelligence/agent-skills/default.nix` to select general
skills by source. Each list contains paths relative to that source's discovery
root; the final path component becomes the deployed skill name. For example:

```nix
mattpocock = [
  "productivity/grilling"
  "in-progress/loop-me"
  "engineering/retro"
  "productivity/writing-for-agents"
];
```

Selections requiring a different deployed name or the source root (`"."`) stay
in `skills.explicit`. Mizchi's transformations stay in `mizchi.nix`, and local
skills remain automatically selected through discovery.

## Web conversion CLI

Web conversion uses the NUR `webforai` package instead of defuddle. Home Manager
and Hermes select the official skill from `pkgs.webforai.src`, keeping its
instructions on the same revision as the CLI. The shared skill transform uses
the Nix executable instead of fetching `webforai-cli` with npx. The remaining
Obsidian skills stay enabled; Hermes removes its previously managed defuddle
skill directory when preparing the service.

## Global mizchi skills

`registry/sources/mizchi.nix` pins the reviewed revision of `mizchi/skills`.
The Home Manager feature selects seven skills in
`modules/features/super-intelligence/agent-skills/mizchi.nix`: maintainer-persona,
extract-glossary, stryker-js, natural-writing-ja, natural-writing-en, ai-index,
and formal-methods-reconciler. They use the existing enabled global targets.

The transforms keep scripts at immutable source paths and use Nix-provided
Node.js, Python, Git, and GitHub CLI binaries. Writing skills share ai-index's
local Python prose lint; it needs no API key and does not determine whether an
author used AI. Maintainer analysis works without drafting or publishing, and
its local policy reuses existing authorization instead of repeating approval
requests at each draft stage. A request for analysis does not authorize posting.

Stryker configuration remains project-local, and formal verification tools are
chosen per task. These skills do not install a test runner or every solver into
all projects. When updating the source pin, check the replacement strings and
upstream scripts as well as the generated skill content.

## Updating sources

From the repository root:

```bash
nix run .#skills-sources-lock
```

The command resolves every manifest using npins and replaces the lock file
atomically. Review and commit both the manifests and the generated lock file.
Changing a manifest without regenerating the lock causes evaluation to fail.
`nix flake update` only updates the remaining flake inputs.

The initial migration preserves the revisions and hashes from `flake.lock`;
it does not update skill content. Subsequent source-lock runs follow the
branches declared in the manifests, except sources with `pin.at` set to an
explicit revision. For those sources, update `pin.at` manually and regenerate
the lock file. Gists use `pin.type = "git"` with `pin.forge = "none"`.

## Testing a local skills checkout

To test unpublished changes, temporarily override the `local` source in
`lib/skill-sources.nix`:

```nix
{ inputs }:
let
  sources = inputs.agent-skills.lib.agent-skills.sourcesFromLock {
    manifestsDir = ../registry/sources;
    lockFile = ../registry/sources.lock.json;
  };
in
sources // {
  local = sources.local // { path = /absolute/path/to/skills; };
}
```

Use an absolute path to the checkout root, which contains `skills/`. Build
with an explicit impure evaluation (replace `<hostname>`):

```bash
# NixOS
nix build --impure '.#nixosConfigurations.<hostname>.config.system.build.toplevel'

# macOS
nix build --impure '.#darwinConfigurations.<hostname>.system'
```

To apply, use `sudo nixos-rebuild switch --impure --flake '.#<hostname>'`
or `sudo darwin-rebuild switch --impure --flake '.#<hostname>'`. Restore the
loader before committing. This override covers all registry
consumers, including Hermes. The old `--override-input skills` option no longer
applies because `skills` is no longer a flake input.
