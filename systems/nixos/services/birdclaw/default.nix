{ inputs, ... }:

{
  imports = [
    inputs.nur-packages.nixosModules.birdclaw
  ];

  services.birdclaw = {
    enable = true;
    port = 3005;
  };
}
