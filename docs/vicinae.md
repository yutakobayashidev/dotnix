# Vicinae extensions

The Home Manager feature in `modules/features/desktop/vicinae/default.nix` installs AI Sessions alongside the existing Vicinae extensions. Its GitHub commit, source hash, and npm dependency hash are pinned, following the existing `mkVicinaeExtension` packaging pattern.

AI Sessions provides Search AI Sessions, Browse AI Projects, and New AI Session. It uses the installed Codex app-server and bundles the Claude Agent SDK as native ESM. No separate Rust build or lastai executable is required. The build copies the SDK and its license into extension assets. Nix includes optional npm dependencies during the build so esbuild can use its pre-fetched platform binary without network access. The Claude native binaries are not copied into extension assets.

The Vicinae user service receives `CODEX_HOME` and `CLAUDE_CONFIG_DIR` from Home Manager's existing session variables when they are configured. Directory preferences do not need duplicate values. Terminal resume uses Vicinae's configured terminal, including Ghostty.

Codex normally uses its existing history index. Use **Rescan Codex History (Slow)** if older sessions are missing. Normal Refresh returns to indexed listing. See the [extension README](https://github.com/yutakobayashidev/vicinae-extension-ai-session#readme) for search limits and Desktop support.

## Updates and application

Update the AI Sessions revision and source hash in the Vicinae module. Recompute the `fetchNpmDeps` hash when the lockfile changes, and build the extension before applying the system configuration. Apply with `nix run .#switch` on a graphical host.

The pinned Home Manager module uses the package name for the installation directory (`ai-sessions-0-unstable-2026-10-13`). A manually installed development copy uses `ai-sessions`; move that copy outside the extensions directory when switching to the declarative installation to avoid duplicate command registrations.

## Verification

On 2026-10-13, the pinned AI Sessions derivation built successfully for `x86_64-linux`. The output contains all three command bundles plus the SDK ESM and license files. The ThinkPad NixOS `system.build.toplevel.drvPath` evaluated successfully, and the resolved Vicinae service environment contains the existing Codex and Claude configuration directories. Nix formatting and whitespace checks passed. System activation was not performed.
