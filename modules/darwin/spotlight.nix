{
  config,
  lib,
  ...
}:

let
  cfg = config.my.services.spotlight;
in
{
  options.my.services.spotlight.enableIndex = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  config.system.activationScripts.spotlight.text =
    if cfg.enableIndex then
      ''
        echo "enabling spotlight indexing..."
        mdutil -Eai on &> /dev/null
      ''
    else
      ''
        echo "disabling spotlight indexing..."
        mdutil -i off -d / &> /dev/null
        mdutil -E / &> /dev/null
      '';
}
