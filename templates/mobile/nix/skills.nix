{ pkgs, agentLib }:
let
  sources = agentLib.sourcesFromLock {
    manifestsDir = ../registry/sources;
    lockFile = ../registry/sources.lock.json;
  };
  catalog = agentLib.discoverCatalog sources;
  names = map (skill: builtins.baseNameOf skill.relPath) (builtins.attrValues catalog);
  # Flat directories work for agents that do not recursively discover skills.
  explicit = pkgs.lib.mapAttrs' (
    _: skill:
    pkgs.lib.nameValuePair (builtins.baseNameOf skill.relPath) {
      from = "android";
      path = skill.relPath;
      rewriteCommands = false;
    }
  ) catalog;
  selection =
    assert builtins.length names == builtins.length (pkgs.lib.unique names);
    agentLib.selectSkills {
      inherit catalog sources;
      skills = explicit;
    };
  bundle = agentLib.mkBundle { inherit pkgs selection; };
  targets = pkgs.lib.genAttrs [ "agents" "codex" "claude" "opencode" ] (
    name: agentLib.defaultLocalTargets.${name} // { enable = true; }
  );
  # Project copies belong to the current user, not the Nix Store's UID/GID.
  syncPkgs = pkgs // {
    rsync = pkgs.writeShellScriptBin "rsync" ''
      args=()
      for arg in "$@"; do
        if [[ "$arg" == -- ]]; then
          args+=(--no-owner --no-group)
        fi
        args+=("$arg")
      done
      exec ${pkgs.rsync}/bin/rsync "''${args[@]}"
    '';
  };
in
{
  inherit bundle;
  shellHook = agentLib.mkShellHook {
    pkgs = syncPkgs;
    inherit bundle targets;
  };
}
