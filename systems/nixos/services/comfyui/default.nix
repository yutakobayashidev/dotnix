_:

{
  services.comfyui = {
    enable = true;
    extraPackages = ps: [ ps.comfyui-manager ];
    extraArgs = [ "--enable-manager" ];
    listen = [ "0.0.0.0" ];
  };

  networking.firewall.allowedTCPPorts = [ 8188 ];
  nixpkgs.config.cudaSupport = true;
}
