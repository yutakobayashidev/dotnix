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
      isDarwin = pkgs.stdenv.isDarwin;
      nom = "${pkgs.nix-output-monitor}/bin/nom";

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
      packages = {
        inherit (pkgs)
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
      }
      // lib.optionalAttrs (!isDarwin) { inherit (pkgs) polycat; }
      // lib.optionalAttrs isDarwin { inherit (pkgs) readout; }
      // lib.optionalAttrs (system == "x86_64-linux") {
        nixos-minimal-iso =
          let
            isoEval = import "${pkgs.path}/nixos/lib/eval-config.nix" {
              system = "x86_64-linux";
              modules = [
                "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                ../../../modules/profiles/nixos/installer.nix
                {
                  nixpkgs.pkgs = lib.mkForce pkgs;
                }
              ];
            };
          in
          isoEval.config.system.build.isoImage;
      };

      apps = {
        build = {
          type = "app";
          meta.description = "Build the current host's Nix configuration";
          program = toString (
            pkgs.writeShellScript "build" ''
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
            pkgs.writeShellScript "switch" ''
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
            pkgs.writeShellScript "treefmt-wrapper" ''
              exec ${config.treefmt.build.wrapper}/bin/treefmt "$@"
            ''
          );
        };
      };
    };
}
