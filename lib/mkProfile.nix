# Build one profile toggle across system and Home Manager module registries.
{ lib }:
{
  name,
  home ? null,
  system ? { },
  nixos ? { },
  darwin ? { },
}:
let
  option.options.my.profiles.${name}.enable = lib.mkEnableOption "${name} profile";

  mkSystem =
    extra:
    { config, options, ... }:
    option
    // {
      config = lib.mkIf config.my.profiles.${name}.enable (
        lib.mkMerge [
          (lib.optionalAttrs (home != null && lib.hasAttrByPath [ "home-manager" "sharedModules" ] options) {
            home-manager.sharedModules = [
              { my.profiles.${name}.enable = lib.mkDefault true; }
            ];
          })
          system
          extra
        ]
      );
    };

  homeModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    option
    // {
      config = lib.mkIf config.my.profiles.${name}.enable (
        if builtins.isFunction home then home (args // { inherit pkgs; }) else home
      );
    };
in
{
  flake.modules = {
    nixos."profile-${name}" = mkSystem nixos;
    darwin."profile-${name}" = mkSystem darwin;
  }
  // lib.optionalAttrs (home != null) {
    homeManager."profile-${name}" = homeModule;
  };
}
