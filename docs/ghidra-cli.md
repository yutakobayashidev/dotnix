# Ghidra CLI

Ghidra CLI replaces the global GhidraMCP integration. The pentest profile no
longer installs Ghidra or registers its MCP bridge. Other pentest tools and
Wireshark capture permissions remain as configured.

Create a project-local environment using the ashiba template:

```bash
nix flake init -t github:yutakobayashidev/ashiba#reverse-native
nix develop
ghidra-cli doctor --runtime
ghidra-cli program import ./target.bin --project target --name target.bin
ghidra-cli decompile main --project target --program target.bin --json
ghidra-cli bridge stop --project target
```

Start agents after entering the shell. agent-skills-nix installs the upstream
CLI skill from the exact same source revision as the executable. Ghidra and a
full JDK are supplied by the NUR package; no GUI plugin setup is needed.

Project databases live in `analysis/projects/`; runtime configuration, caches
and logs live in `analysis/runtime/`. Keep the project root and database paths
free of dot-prefixed directory components for Ghidra 12.1+. Keep original
binaries and analysis reports separately. Stop the bridge before opening the
same database in the GUI or updating the runtime. Shell exit does not stop it.

For composition with another flake-parts environment, import
`inputs.ashiba.flakeModules.reverse-native` and use the module's
`perSystem.devshells.default` settings. See the
[template documentation](https://github.com/yutakobayashidev/ashiba/tree/main/reverse-native).

For APK analysis, add `inputs.ashiba.flakeModules.reverse-android`. For SDK,
emulator, and Maestro support, also add `inputs.ashiba.flakeModules.android` and
set `perSystem.ashiba.android.acceptLicense = true` after reviewing the license.
Skills from these modules are collected into a single synchronization hook.
Additional tools such as GDB belong in `perSystem.devshells.default.packages`.

The migration takes effect on the next Home Manager/system activation. Existing
Ghidra projects and user data are not removed or converted automatically.
