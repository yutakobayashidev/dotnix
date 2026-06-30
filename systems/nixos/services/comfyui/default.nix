{ inputs, ... }:

{
  imports = [
    inputs.comfyui-nix.nixosModules.default
  ];

  services.comfyui = {
    enable = true;
    gpuSupport = "cuda";
    enableManager = true;
    listenAddress = "0.0.0.0";
    openFirewall = true;
  };
}
