_:

{
  flake.modules.homeManager.shortcut-cli =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.shortcut-cli ];
    };
}
