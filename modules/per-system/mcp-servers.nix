{ inputs, ... }:
{
  imports = [ inputs.mcp-servers-nix.flakeModule ];

  perSystem = _: {
    mcp-servers = {
      flavors.claude-code.enable = true;

      programs = {
        nixos.enable = true;
        terraform.enable = true;
      };
    };
  };
}
