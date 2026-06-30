{
  self,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ../common.nix
    ../shared/comin/alloy.nix
    ../../modules/darwin
    ../../modules/shared/nixpkgs
    inputs.comin.darwinModules.comin
    inputs.sops-nix.darwinModules.sops
    ../../modules/profiles/darwin/base.nix
  ];

  my.nixpkgs = {
    enable = true;
    permittedInsecurePackages = [
      "python3.13-ecdsa-0.19.2"
    ];
  };

  nixpkgs = {
    overlays = [
      inputs.brew-nix.overlays.default
      inputs.llm-agents.overlays.default
      (_final: _prev: {
        _tree-sitter-moonbit = inputs.tree-sitter-moonbit;
      })
      (
        _final: prev:
        let
          inherit (prev.stdenv.hostPlatform) system;
        in
        {
          bird = inputs.bird.packages.${system}.bird;
          discrawl = inputs.nix-openclaw-tools.packages.${system}.discrawl;
          edcb-tools = inputs.edcb-tools.packages.${system}.edcb-tools;
          ghostty = inputs.ghostty.packages.${system}.default;
          gogcli = inputs.nix-openclaw-tools.packages.${system}.gogcli;
          gh-graph = inputs.gh-graph.packages.${system}.default;
          gh-nippou = inputs.gh-nippou.packages.${system}.default;
          immich-go-no-docs = prev.symlinkJoin {
            name = "immich-go-no-docs";
            paths = [ prev.immich-go ];
            postBuild = ''
              rm -f $out/bin/docs
            '';
          };
          moonbit-lsp =
            let
              versions = import "${inputs.moonbit-overlay}/versions.nix" prev.lib;
              inherit (versions) latest;
              targets = {
                x86_64-linux = "linux-x86_64";
                aarch64-linux = "linux-aarch64";
                aarch64-darwin = "darwin-aarch64";
              };
              target = targets.${system} or null;
              hashAttr = if target != null then "${target}-toolchainsHash" else null;
            in
            if target != null && builtins.hasAttr hashAttr latest then
              prev.stdenv.mkDerivation {
                pname = "moonbit-lsp";
                inherit (latest) version;
                src = prev.fetchurl {
                  url = "https://github.com/moonbit-community/moonbit-overlay/releases/download/${prev.lib.escapeURL latest.version}/moonbit-${target}.tar.gz";
                  hash = latest.${hashAttr};
                };
                sourceRoot = ".";
                installPhase = ''
                  mkdir -p $out/bin
                  cp bin/moonbit-lsp $out/bin/moonbit-lsp
                  chmod +x $out/bin/moonbit-lsp
                '';
              }
            else
              null;
          repiq = inputs.repiq.packages.${system}.default.overrideAttrs (_: {
            doCheck = !prev.stdenv.hostPlatform.isDarwin;
          });
          version-lsp = inputs.version-lsp.packages.${system}.default;
        }
      )
      inputs.rustowl-flake.overlays.default
      inputs.firefox-addons.overlays.default
      inputs.nix-cachyos-kernel.overlays.default
      inputs.nur-packages.overlays.default
      inputs.birdclaw.overlays.default
      inputs.nix-topology.overlays.default
    ]
    ++ lib.attrValues self.overlays;
  };

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "/Users/${username}/.config/sops/age/keys.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/yutakobayashidev/dotnix";
      }
    ];
  };

  services.prometheus.exporters.node.enable = true;
  users.users._prometheus-node-exporter.home = lib.mkForce "/private/var/lib/prometheus-node-exporter";

  users.users.${username}.home = "/Users/${username}";

  nix = {
    settings = {
      trusted-users = [
        "root"
        username
      ];
      always-allow-substitutes = true;
    };
    gc.interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
  };

  system = {
    primaryUser = username;
    stateVersion = 6;
    startup.chime = false;
  };

  home-manager.users.${username} = {
    home.packages = with pkgs; [
      docker-client
      docker-buildx
    ];
    services.colima = {
      enable = true;
      profiles.default.settings = {
        cpu = 8;
        memory = 8;
        runtime = "docker";
        vmType = "vz";
        mountType = "virtiofs";
        rosetta = true;
      };
    };
  };

  my.services = {
    caffeinate = {
      enable = true;
      preventSleepOnCharge = true;
    };
    newsyslog.enable = true;
    spotlight.enableIndex = true;
  };
}
