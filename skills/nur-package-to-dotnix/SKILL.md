---
name: nur-package-to-dotnix
description: Add a requested application to dotnix, checking existing Nix packages first and packaging it in yutakobayashidev/nur-packages when needed. Use for requests to add an upstream repository or CLI through NUR and wire it into dotnix.
---

# Add a package through NUR

Work from the dotnix checkout. Read each repository's agent instructions and inspect its current changes before editing. Locate other repositories with `ghq list -p`; use `ghq get` when a required checkout is missing. Keep unrelated changes intact, including existing edits to package exports and lock files.

## 1. Choose the package source

Check the package sets already available in dotnix, including the pinned `llm-agents.nix` input for agent tools. Inspect sibling attributes when a product has separate editions or major versions. If absent from the pin, check upstream's current package list before concluding it is unavailable.

An existing suitable package satisfies an availability request: use it instead of duplicating it in NUR unless the user explicitly requests a separate package. If only a newer upstream input contains it, assess the required input update. Continue below when a NUR package is needed.

## 2. Package and validate in nur-packages

Read nearby packages, `default.nix`, and the flake outputs to follow the repository's packaging and export conventions. Inspect the requested upstream's release, license, build instructions, runtime requirements, and executable names. Choose a pinned source and verify all fetch/dependency hashes. Preserve an explicitly requested source-build approach.

Export the derivation through the existing NUR interface. Build the named package, then exercise its executable. For a TUI or service, verify startup as well as help/version output; help alone may bypass runtime initialization. Keep smoke tests isolated from existing profiles and credentials, and avoid authenticated requests unless needed and authorized. Report platforms that were not tested.

For npm distribution tarballs, inspect whether they contain built output and whether lifecycle scripts still require development tools. Keep the manifest and generated lock consistent. Check native runtime dependencies and any Nix-specific fixes in related packages rather than assuming a successful npm install proves compatibility.

Completion: the exported package builds, its executable starts, and source/dependency hashes are fixed.

## 3. Integrate with dotnix

Follow `docs/configuration.md` and nearby feature modules. Put the tool in an existing purpose namespace under `modules/features/`; agent tools currently belong under `super-intelligence/`. Use the established `my.programs.<tool>.enable` option and enable it from the appropriate profile or requested host. Keep runtime credentials and optional services separate from package installation.

Test unpublished NUR changes with the local checkout, without saving a local path into `flake.lock`:

```sh
nix eval --no-write-lock-file \
  --override-input nur-packages path:/absolute/path/to/nur-packages \
  '.#nixosConfigurations.<host>.config.home-manager.users.<user>.my.programs.<tool>.enable'
```

Replace the example paths and attributes with the actual checkout, platform, host, and user. Also evaluate the selected package in `home.packages`; an enabled option alone does not prove installation. Evaluate system assertions when system services or profiles are affected. Ensure new files are included in the flake source used for validation.

## 4. Publish and pin within the requested scope

Use existing authorization for commit, push, and activation; this skill grants none by itself. When publishing NUR is within scope, commit only the package changes, publish them to the intended branch, and update only `nur-packages` in dotnix:

```sh
nix flake update nur-packages
```

If remote main has advanced or the checkout contains unrelated changes, use an isolated worktree based on the current remote branch. Preserve the original worktree. Compare the lock before and after to verify that unrelated inputs stayed unchanged, then repeat the relevant dotnix evaluation against the published pin.

When publishing is outside scope, leave a validated local change and clearly state that the remote input cannot yet provide it. Do not claim installation or deployment from a local override. Commit/push dotnix and run `switch` only when those actions are within the user's request; otherwise give the remaining command.

Completion report: package/version and source, NUR publication state, dotnix integration and pin state, verification performed, and whether activation remains.
