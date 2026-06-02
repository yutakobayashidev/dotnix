{ mkPkgs, ... }:
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      isDarwin = builtins.match ".*-darwin" system != null;
      localPkgs = mkPkgs system;
      nom = "${localPkgs.nix-output-monitor}/bin/nom";

      isAgentCheck = ''
        IS_AI_AGENT=false
        for var in CLAUDE_CODE CLAUDECODE CODEX_SANDBOX CODEX_THREAD_ID GEMINI_CLI OPENCODE AUGMENT_AGENT GOOSE_PROVIDER CURSOR_AGENT AI_AGENT; do
          eval "val=\''${!var:-}"
          if [ -n "$val" ]; then
            IS_AI_AGENT=true
            break
          fi
        done
      '';
    in
    {
      packages =
        let
          polycat' = lib.optionalAttrs (!isDarwin) { inherit (localPkgs) polycat; };
          readout' = lib.optionalAttrs isDarwin { inherit (localPkgs) readout; };
        in
        polycat'
        // readout'
        // {
          inherit (localPkgs)
            bumblebee
            difit
            git-now
            jj-desc
            keifu
            pretty-ts-errors-markdown
            roots
            session-tts-codex
            similarity-ts
            tunnelto
            ;
        };

      apps = {
        build = {
          type = "app";
          meta.description = "Build the current host's Nix configuration";
          program = toString (
            localPkgs.writeShellScript "build" ''
              set -e
              ${isAgentCheck}

              HOSTNAME="$(hostname)"

              ${
                if isDarwin then
                  ''
                    echo "Building darwin configuration for $HOSTNAME..."
                    if [ "$IS_AI_AGENT" = true ]; then
                      nix build ".#darwinConfigurations.$HOSTNAME.system"
                    else
                      ${nom} build ".#darwinConfigurations.$HOSTNAME.system"
                    fi
                  ''
                else
                  ''
                    echo "Building NixOS configuration for $HOSTNAME..."
                    if [ "$IS_AI_AGENT" = true ]; then
                      nix build ".#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
                    else
                      ${nom} build ".#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
                    fi
                  ''
              }

              echo "Build successful! Run 'nix run .#switch' to apply."
            ''
          );
        };

        switch = {
          type = "app";
          meta.description = "Switch to the current host's Nix configuration";
          program = toString (
            localPkgs.writeShellScript "switch" ''
              set -eo pipefail
              ${isAgentCheck}

              HOSTNAME="$(hostname)"

              ${
                if isDarwin then
                  ''
                    echo "Switching to darwin configuration for $HOSTNAME..."
                    if [ "$IS_AI_AGENT" = true ]; then
                      sudo darwin-rebuild switch --flake ".#$HOSTNAME"
                    else
                      sudo darwin-rebuild switch --flake ".#$HOSTNAME" |& ${nom}
                    fi
                  ''
                else
                  ''
                    echo "Switching to NixOS configuration for $HOSTNAME..."
                    if [ "$IS_AI_AGENT" = true ]; then
                      sudo nixos-rebuild switch --flake ".#$HOSTNAME"
                    else
                      sudo nixos-rebuild switch --flake ".#$HOSTNAME" |& ${nom}
                    fi
                  ''
              }

              echo "Done!"
            ''
          );
        };

        fmt = {
          type = "app";
          meta.description = "Format all files with treefmt";
          program = toString (
            localPkgs.writeShellScript "treefmt-wrapper" ''
              exec ${config.treefmt.build.wrapper}/bin/treefmt "$@"
            ''
          );
        };
      };
    };
}
