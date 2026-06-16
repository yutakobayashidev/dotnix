{ mkPkgs, ... }:
{
  perSystem =
    {
      agentSkillsShellHook,
      config,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      localPkgs = mkPkgs system;
      mkProvider = localPkgs.opentofu.plugins.mkProvider;
    in
    {
      devShells.default = localPkgs.mkShell {
        packages = [
          config.pre-commit.settings.package
        ]
        ++ config.pre-commit.settings.enabledPackages
        ++ [
          localPkgs.oci-cli
          localPkgs.terragrunt
          localPkgs.nix-fast-build
          localPkgs.ssh-to-age
          localPkgs.tflint
          localPkgs.sops
          localPkgs.packer
          localPkgs.nomad
          localPkgs.vault
          localPkgs.checkov
          localPkgs.pike
          localPkgs.skill-scanner
          localPkgs.skillspector
          (localPkgs.opentofu.withPlugins (p: [
            p.go-gitea_gitea
            p.oracle_oci
            p.carlpett_sops
            p.hashicorp_external
            p.hashicorp_null
            p.hashicorp_random
            (mkProvider {
              owner = "takeokunn";
              repo = "terraform-provider-cachix";
              rev = "v1.0.1";
              hash = "sha256-mhVVpPcyuHhxNGcok5ddTjaMtSaNxkwrEz81hA6MFVM=";
              vendorHash = "sha256-azVDDWewb42DB8OyMAxV98mLDa9VVG1nJNscBim6+mw=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/takeokunn/cachix";
              provider-source-address = "registry.opentofu.org/takeokunn/cachix";
            })
            (mkProvider {
              owner = "breml";
              repo = "terraform-provider-uptimekuma";
              rev = "v0.3.2";
              hash = "sha256-/szEaiMkFpcQnyxh230whyCEwoaJ8FgGMQa9Bu/6frA=";
              vendorHash = "sha256-vo4eLZjS4J6c5WsdqNQDYduWtlXMCGsnFXUF3Ead910=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/breml/uptimekuma";
              provider-source-address = "registry.opentofu.org/breml/uptimekuma";
            })
            p.tailscale_tailscale
          ]))
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}
          ${config.mcp-servers.shellHook}
          ${agentSkillsShellHook}
        '';
      };

      devShells.infra-ci = localPkgs.mkShell {
        packages = [
          (localPkgs.opentofu.withPlugins (p: [
            p.go-gitea_gitea
            p.oracle_oci
            p.carlpett_sops
            p.hashicorp_external
            p.hashicorp_null
            p.hashicorp_random
            (mkProvider {
              owner = "takeokunn";
              repo = "terraform-provider-cachix";
              rev = "v1.0.1";
              hash = "sha256-mhVVpPcyuHhxNGcok5ddTjaMtSaNxkwrEz81hA6MFVM=";
              vendorHash = "sha256-azVDDWewb42DB8OyMAxV98mLDa9VVG1nJNscBim6+mw=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/takeokunn/cachix";
              provider-source-address = "registry.opentofu.org/takeokunn/cachix";
            })
            (mkProvider {
              owner = "breml";
              repo = "terraform-provider-uptimekuma";
              rev = "v0.3.2";
              hash = "sha256-/szEaiMkFpcQnyxh230whyCEwoaJ8FgGMQa9Bu/6frA=";
              vendorHash = "sha256-vo4eLZjS4J6c5WsdqNQDYduWtlXMCGsnFXUF3Ead910=";
              spdx = "MIT";
              homepage = "https://registry.terraform.io/providers/breml/uptimekuma";
              provider-source-address = "registry.opentofu.org/breml/uptimekuma";
            })
            p.tailscale_tailscale
          ]))
        ];
      };
    };
}
