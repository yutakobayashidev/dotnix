{ config, lib, ... }:

let
  cfg = config.my.nixpkgs;
in
{
  options.my.nixpkgs = {
    enable = lib.mkEnableOption "Nixpkgs configuration";

    allowUnfree = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Whether to allow unfree packages.";
    };

    permittedInsecurePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "python3.13-ecdsa-0.19.2" ];
      description = "Insecure packages permitted for this host.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config = {
      inherit (cfg) allowUnfree permittedInsecurePackages;
    };
  };
}
