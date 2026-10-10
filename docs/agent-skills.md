# Agent skill sources

Skill-only repositories use the [upstream source registry](https://github.com/Kyure-A/agent-skills-nix/tree/dc122af897ab9a685c20ae54c639021619dbbb52/examples/source-registry).

- `registry/sources/*.nix` declares each repository, branch, and discovery settings.
- `registry/sources.lock.json` snapshots those manifests and pins revisions and hashes.
- `lib/skill-sources.nix` loads the registry for Home Manager, the development shell, and Hermes.
- Feature modules retain skill selection, package dependencies, and content transformations.

Package-providing repositories continue to use flake inputs so their skills and
packages share a revision. Repository-local skills continue to use local paths.

## Global mizchi skills

`registry/sources/mizchi.nix` pins the reviewed revision of `mizchi/skills`.
The Home Manager feature selects seven skills in
`modules/features/coding-agents/agent-skills/mizchi.nix`: maintainer-persona,
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
