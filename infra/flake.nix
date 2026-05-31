{
  description = "Infrastructure deployment environment for B450M-Pro4";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              terraform
              opentofu
              terragrunt
              tflint
              sops
              packer
              nomad
              vault
            ];

            shellHook = ''
              echo "infra devShell loaded"
              echo "  terraform  $(terraform --version 2>&1 | head -1)"
              echo "  opentofu   $(tofu --version 2>&1 | head -1)"
            '';
          };

          terraform = pkgs.mkShellNoCC {
            packages = with pkgs; [
              terraform
              terragrunt
              tflint
              checkov
              sops
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
