_:

{
  flake.modules.homeManager.kohaku-cli =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.kohaku-cli ];
    };
}
