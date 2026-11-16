# DIY development

Use the project-local `diy-workflow` skill installed by agent-skills-nix on shell
entry. Start agents from this root after entering the appropriate shell.
See README.md for shell selection, mutable toolchain caches and host device access.
Keep the selected board, units, fabrication constraints and validation results
with the project's native design files. Dependencies downloaded by Arduino or
PlatformIO need project-level version pins in addition to flake.lock.
