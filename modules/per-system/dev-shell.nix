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
      devShells = {
        default = pkgs.mkShell {
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

        # The recovered linux_amd64 package matches the existing lock's h1 hash.
        pocket-id-ci =
          let
            providerArchive = pkgs.fetchurl {
              url = "https://github.com/yutakobayashidev/dotnix/releases/download/pocketid-provider-v2.5.0-recovery/pocketid-2.5.0-linux-amd64-recovered.zip";
              sha256 = "f7d8a82d44c8c6fce971ac5e0d2f24773fead917f54a8370512be061aa1dda7f";
            };
            providerMirror = pkgs.runCommand "pocketid-provider-mirror" { } ''
              mkdir -p "$out/registry.terraform.io/trozz/pocketid"
              ln -s ${providerArchive} "$out/registry.terraform.io/trozz/pocketid/terraform-provider-pocketid_2.5.0_linux_amd64.zip"
            '';
          in
          pkgs.mkShell (
            {
              packages = [
                pkgs.opentofu
                pkgs.python3
              ];
            }
            // pkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
              TF_CLI_CONFIG_FILE = pkgs.writeText "pocketid-tofu.tfrc" ''
                provider_installation {
                  filesystem_mirror {
                    path = "${providerMirror}"
                    include = ["registry.terraform.io/trozz/pocketid"]
                  }
                  direct {
                    exclude = ["registry.terraform.io/trozz/pocketid"]
                  }
                }
              '';
            }
          );

        infra-ci = pkgs.mkShell {
          packages = [
            pkgs.age
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
    };
}
