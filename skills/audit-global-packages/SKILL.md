---
name: audit-global-packages
description: Audit dotnix's globally installed CLI tools and move low-value permanent installations to on-demand nix shell commands when requested. Use for slimming host packages and skill dependencies, not removing globally available skill instructions.
---

# Audit global packages

Keep frequently used tools and runtime dependencies installed. Prefer `nix shell` for occasional, standalone diagnostics. Keep this audit small: inspect evidence, propose a short list, and migrate only within the requested scope.

## Audit

1. Read repository instructions and current changes. Inspect `home.packages`, `environment.systemPackages`, `programs.*`, feature/profile enables, and agent-skill `packages`/transforms. Map candidates to the hosts and profiles that actually install them; a declaration alone does not prove installation.
2. Trace each candidate's consumers with `rg`: services, timers, scripts, aliases, keybindings, wrappers, dev shells, and skill commands. Use recent shell history when available to support usage frequency. No history is not proof of disuse; background and agent usage may be absent.
3. Classify a small set of candidates:
   - **Keep:** everyday shell tools, service/runtime dependencies, offline essentials, or tools with required desktop/system integration.
   - **On demand:** infrequent standalone CLIs with a verified package source and no unattended consumer requiring them on PATH.
   - **Project scope:** project-specific toolchains belong in an existing devShell when they need coordinated dependencies.
   - **Unknown:** insufficient evidence; state what needs checking.

Report package, installation location/hosts, consumers or usage evidence, recommendation, and replacement command. Consider rebuild cost and closure size, but do not equate package size with marginal disk savings: dependencies may be shared. An audit request alone does not authorize removals.

## Migrate when requested

- Use the existing pinned package source and verify its attribute, executable, platform support, and required overrides. Do not silently replace a custom package with a different nixpkgs variant. Locate other repositories with `ghq` if their skill source needs editing.
- Replace interactive instructions with an explicit command, for example:

  ```bash
  nix shell 'github:NixOS/nixpkgs/REV#PACKAGE' -c EXECUTABLE ARGS
  ```

  Resolve the placeholders before presenting a runnable command. Prefer an existing project pin for project workflows. Check the same package with `nix build --dry-run --no-link --option allow-import-from-derivation false` before obtaining it. If it needs costly compilation, report that tradeoff; `nix shell` postpones acquisition, it does not guarantee a cache hit. To forbid compilation during a smoke check, also pass `--max-jobs 0 --builders '' --option allow-import-from-derivation false` to `nix shell`.

- Remove only the redundant permanent installation and skill package dependency. Update transforms that inject store paths or dependency instructions. Keep skill discovery enabled; globally useful instructions do not require globally installed executables. Preserve configuration, secrets, and service integration still in use.
- Do not replace unattended service commands with network-dependent `nix shell` calls. Keep declarative runtime dependencies, or propose a separate service redesign. Do not add wrappers, flake inputs, or an automation framework just for this migration.
- Verify the resulting command and affected host package list. Check that the smoke test runs the executable supplied by `nix shell`, not a leftover global binary. Check system assertions when service/profile wiring changes. Respect concurrent-build restrictions and available disk space; report checks that could not run.

Finish with the small diff, verified commands, remaining dependencies, and any offline/cold-start tradeoff. Removing a package declaration does not immediately reclaim disk space: old generations and other references may retain it. Do not run GC, commit/push, or activate a host unless requested.
