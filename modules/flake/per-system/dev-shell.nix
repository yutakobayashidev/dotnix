{ mkPkgs, ... }:
{
  perSystem =
    {
      agentSkillsShellHook,
      config,
      pkgs,
      sgconfig,
      ...
    }:
    let
      p = mkPkgs pkgs.stdenv.hostPlatform.system;
    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.pre-commit.settings.package
        ]
        ++ config.pre-commit.settings.enabledPackages
        ++ [
          p.oci-cli
          p.terragrunt
          p.nix-fast-build
          p.ssh-to-age
          p.tflint
          p.sops
          p.packer
          p.nomad
          p.vault
          p.checkov
          p.pike
          p.skill-scanner
          p.skillspector
          p.actionlint
          p.pinact
          p.ghalint
          p.zizmor
          pkgs.ast-grep
          pkgs.tree-sitter
          (p.opentofu.withPlugins (pl: [
            pl.go-gitea_gitea
            pl.oracle_oci
            pl.carlpett_sops
            pl.hashicorp_external
            pl.hashicorp_null
            pl.hashicorp_random
            (p.opentofu.plugins.mkProvider {
              owner = "takeokunn";
              repo = "terraform-provider-cachix";
              rev = "v1.0.1";
              hash = "sha256-mhVVpPcyuHhxNGcok5ddTjaMtSaNxkwrEz81hA6MFVM=";
              vendorHash = "sha256-azVDDWewb42DB8OyMAxV98mLDa9VVG1nJNscBim6+mw=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/takeokunn/cachix";
              provider-source-address = "registry.opentofu.org/takeokunn/cachix";
            })
            (p.opentofu.plugins.mkProvider {
              owner = "breml";
              repo = "terraform-provider-uptimekuma";
              rev = "v0.3.2";
              hash = "sha256-/szEaiMkFpcQnyxh230whyCEwoaJ8FgGMQa9Bu/6frA=";
              vendorHash = "sha256-vo4eLZjS4J6c5WsdqNQDYduWtlXMCGsnFXUF3Ead910=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/breml/uptimekuma";
              provider-source-address = "registry.opentofu.org/breml/uptimekuma";
            })
            pl.tailscale_tailscale
          ]))
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}
          ${config.mcp-servers.shellHook}
          ${agentSkillsShellHook}
          ln -sf ${sgconfig} sgconfig.yml
        '';
      };

      devShells.infra-ci = pkgs.mkShell {
        packages = [
          (p.opentofu.withPlugins (pl: [
            pl.go-gitea_gitea
            pl.oracle_oci
            pl.carlpett_sops
            pl.hashicorp_external
            pl.hashicorp_null
            pl.hashicorp_random
            (p.opentofu.plugins.mkProvider {
              owner = "takeokunn";
              repo = "terraform-provider-cachix";
              rev = "v1.0.1";
              hash = "sha256-mhVVpPcyuHhxNGcok5ddTjaMtSaNxkwrEz81hA6MFVM=";
              vendorHash = "sha256-azVDDWewb42DB8OyMAxV98mLDa9VVG1nJNscBim6+mw=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/takeokunn/cachix";
              provider-source-address = "registry.opentofu.org/takeokunn/cachix";
            })
            (p.opentofu.plugins.mkProvider {
              owner = "breml";
              repo = "terraform-provider-uptimekuma";
              rev = "v0.3.2";
              hash = "sha256-/szEaiMkFpcQnyxh230whyCEwoaJ8FgGMQa9Bu/6frA=";
              vendorHash = "sha256-vo4eLZjS4J6c5WsdqNQDYduWtlXMCGsnFXUF3Ead910=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/breml/uptimekuma";
              provider-source-address = "registry.opentofu.org/breml/uptimekuma";
            })
            pl.tailscale_tailscale
          ]))
        ];
      };
    };
}
