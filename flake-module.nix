{
  self,
  inputs,
  lib,
  config,
  ...
}:

let
  inherit (builtins) attrValues pathExists;
  inherit (lib)
    filter
    last
    mapAttrs
    mkOption
    optionalAttrs
    optionals
    splitString
    types
    ;

  getDefaultPlatform =
    system: if (last (splitString "-" system)) == "linux" then "nixos" else "darwin";

  maybePath = path: if pathExists path then path else null;

  systemConfigurations =
    platform: hostname: attrs:
    if platform == "nixos" then
      { nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem attrs; }
    else if platform == "darwin" then
      { darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem attrs; }
    else
      { nixOnDroidConfigurations.${hostname} = inputs.nix-on-droid.lib.nixOnDroidConfiguration attrs; };
in
{
  options.hosts = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            system = mkOption {
              default = "x86_64-linux";
              type = types.str;
            };

            platform = mkOption {
              default = getDefaultPlatform config.hosts.${name}.system;
              type = types.enum [
                "nixos"
                "darwin"
                "android"
              ];
            };

            modules = mkOption {
              default = [ ];
              type = types.listOf types.unspecified;
            };

            username = mkOption {
              default = "yuta";
              type = types.str;
            };

            specialArgs = mkOption {
              default = { };
              type = types.attrs;
            };
          };
        }
      )
    );
  };

  config = rec {
    flake = lib.foldAttrs (host: acc: host // acc) { } (
      attrValues (
        mapAttrs (
          name: cfg:
          systemConfigurations cfg.platform name (
            {
              modules =
                filter (x: x != null) [
                  (maybePath ./systems/${cfg.platform}/${name})
                  (maybePath ./homes/${cfg.platform}/${name})
                ]
                ++ cfg.modules;
              "${if cfg.platform == "android" then "extraS" else "s"}pecialArgs" = {
                inherit self inputs;
                inherit (cfg) username;
              }
              // cfg.specialArgs;
            }
            // optionalAttrs (cfg.platform != "android") { inherit (cfg) system; }
            // optionalAttrs (cfg.platform == "android") {
              pkgs = import inputs.nixpkgs {
                inherit (cfg) system;
                config.allowUnfree = true;
                overlays = [
                  inputs.llm-agents.overlays.default
                  (_final: _prev: {
                    _nix-openclaw-tools = inputs.nix-openclaw-tools;
                    _ghostty = inputs.ghostty;
                    _repiq = inputs.repiq;
                    _moonbit-overlay = inputs.moonbit-overlay;
                    _tree-sitter-moonbit = inputs.tree-sitter-moonbit;
                  })
                  inputs.gh-nippou.overlays.default
                  inputs.gh-graph.overlays.default
                  inputs.rustowl-flake.overlays.default
                  inputs.firefox-addons.overlays.default
                  inputs.nix-cachyos-kernel.overlays.default
                  inputs.nur-packages.overlays.default
                  inputs.birdclaw.overlays.default
                  inputs.nix-topology.overlays.default
                  inputs.nix-on-droid.overlays.default
                ]
                ++ lib.attrValues self.overlays;
              };
              home-manager-path = inputs.home-manager.outPath;
            }
          )
        ) config.hosts
      )
    );

    perSystem =
      { lib, system, ... }:
      {
        checks =
          let
            currentSystemConfigurations = lib.filterAttrs (
              _name: value: value.pkgs.stdenv.hostPlatform.system == system
            ) ((flake.nixosConfigurations or { }) // (flake.darwinConfigurations or { }));
          in
          builtins.mapAttrs (_name: value: value.config.system.build.toplevel) currentSystemConfigurations;
      };
  };
}
