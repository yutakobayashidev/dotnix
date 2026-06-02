# Lessons

- When the user narrows scope after an over-broad interpretation, update only the explicitly named target and do not apply the same change to adjacent systems without a fresh request.
- Keep AGENTS.md high-level unless the user asks for operational detail. Do not add individual skill names, external catalogs, deploy paths, or file layout lists there when dedicated docs/config are the source of truth.
- Avoid aggregate `packages.nix` Home Manager modules when the repo is organized around feature modules. Put each tool's package with the module that configures/enables that tool, and keep broad CLI miscellany in `applications/misc`.
- When the user asks to port a reference architecture, keep the parts they named as important. A minimal first pass is fine only when it preserves the requested architectural properties.
- When the user points to a reference project, preserve its file/module boundaries unless there is a concrete reason to deviate. Do not collapse service-per-file layouts into a single aggregate module.
- Do not invent extra service module boundaries while porting a reference. If the reference enables a NixOS service in host/common config, mirror that shape unless the user asks for a new abstraction.
- When a reference manages Grafana `secret_key` through sops, do not replace it with runtime-generated local state. Add the appropriate sops rule and encrypted secret file.
- When adding disko to an existing host, distinguish install-only destructive commands from normal rebuilds. Do not let generated partlabel mounts replace known-good UUID mounts unless the current disk labels are verified or the host is being freshly provisioned.
- When creating a skill from a talk or slide deck that centers on code examples, include a few representative bad/good snippets from the source material. Pure heuristics are less reusable when the original concept is taught through code contrast.
- Never generate or store secrets, API tokens, or age private keys under `/tmp` or `/private/tmp`. Use the final persistent location or a repo-external durable path with restrictive permissions.
- When passing a secret to a command, avoid TTY sessions because input can be echoed into logs. Use non-echoing stdin or a tool-specific secret input path, and verify without printing decrypted values.
- When a user asks to add a skill in this repository, wire it into `agent-skills-nix` unless they explicitly ask for an immediate local install.
- When upgrading a release-pinned flake input, inspect and update the declared release branch in `flake.nix`; refreshing the lock file alone cannot move from one release series to another.
- For Codex Bash tool adapters, inspect the exported environment before choosing a session identifier. Codex exposes `CODEX_THREAD_ID`; hook payloads separately provide the same logical identifier as JSON `session_id`.
- When verification exposes failures in the component being modified, investigate and fix them before stopping. Do not leave a failing suite behind merely because the failures predated the narrow trigger change.
