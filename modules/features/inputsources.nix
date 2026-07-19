_:

{
  flake.modules.darwin."inputsources" =
    { lib, ... }:

    {
      options.system.defaults.inputsources.AppleEnabledThirdPartyInputSources = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.attrs);
        default = null;
        description = "Third-party input sources enabled for input methods.";
      };
    };
}
