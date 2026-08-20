{ pkgs, ... }:

{
  services.comfyui = {
    enable = true;
    package = pkgs.comfyui.override { withManager = true; };
    listen = [ "0.0.0.0" ];
  };

  networking.firewall.allowedTCPPorts = [ 8188 ];
  nixpkgs.config.cudaSupport = true;
}
