{ pkgs, ... }:

{
  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = true;
    steam.importOXRRuntimes = true;
    package = pkgs.wivrn.override { cudaSupport = true; };
  };
}
