{
  perSystem =
    {
      agentSkillsShellHook,
      config,
      pkgs,
      sgconfig,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.pre-commit.settings.package
        ]
        ++ config.pre-commit.settings.enabledPackages
        ++ [
          pkgs.stable.oci-cli
          pkgs.terragrunt
          pkgs.nix-fast-build
          pkgs.ssh-to-age
          pkgs.tflint
          pkgs.sops
          pkgs.packer
          pkgs.nomad
          pkgs.vault
          pkgs.stable.checkov
          pkgs.pike
          pkgs.skill-scanner
          pkgs.skillspector
          pkgs.actionlint
          pkgs.pinact
          pkgs.ghalint
          pkgs.zizmor
          pkgs.ast-grep
          pkgs.tree-sitter
          (pkgs.opentofu.withPlugins (pl: [
            pl.go-gitea_gitea
            pl.oracle_oci
            pl.carlpett_sops
            pl.hashicorp_external
            pl.hashicorp_null
            pl.hashicorp_random
            (pkgs.opentofu.plugins.mkProvider {
              owner = "takeokunn";
              repo = "terraform-provider-cachix";
              rev = "v1.0.1";
              hash = "sha256-mhVVpPcyuHhxNGcok5ddTjaMtSaNxkwrEz81hA6MFVM=";
              vendorHash = "sha256-azVDDWewb42DB8OyMAxV98mLDa9VVG1nJNscBim6+mw=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/takeokunn/cachix";
              provider-source-address = "registry.opentofu.org/takeokunn/cachix";
            })
            (pkgs.opentofu.plugins.mkProvider {
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
          (pkgs.opentofu.withPlugins (pl: [
            pl.go-gitea_gitea
            pl.oracle_oci
            pl.carlpett_sops
            pl.hashicorp_external
            pl.hashicorp_null
            pl.hashicorp_random
            (pkgs.opentofu.plugins.mkProvider {
              owner = "takeokunn";
              repo = "terraform-provider-cachix";
              rev = "v1.0.1";
              hash = "sha256-mhVVpPcyuHhxNGcok5ddTjaMtSaNxkwrEz81hA6MFVM=";
              vendorHash = "sha256-azVDDWewb42DB8OyMAxV98mLDa9VVG1nJNscBim6+mw=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/takeokunn/cachix";
              provider-source-address = "registry.opentofu.org/takeokunn/cachix";
            })
            (pkgs.opentofu.plugins.mkProvider {
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
