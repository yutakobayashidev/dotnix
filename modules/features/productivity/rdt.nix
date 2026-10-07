{ inputs, ... }:

{
  flake.modules.homeManager.rdt =
    { pkgs, ... }:
    {
      home.packages = [ inputs.rdt-gateway.packages.${pkgs.stdenv.hostPlatform.system}.rdt-cli ];
      home.sessionVariables.RDT_GATEWAY_URL = "https://rdt.home.yutakobayashi.com";
    };
}
