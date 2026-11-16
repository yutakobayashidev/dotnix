{ pkgs, agentLib }:
let
  sources.local.path = ../skills;
  selection = agentLib.selectSkills {
    inherit sources;
    catalog = agentLib.discoverCatalog sources;
    skills.diy-workflow = {
      from = "local";
      path = "diy-workflow";
      rewriteCommands = false;
    };
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
