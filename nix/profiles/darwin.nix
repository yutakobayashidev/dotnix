{ ... }:
{
  home-manager.users.yuta.imports = [
    ./../modules/home/programs/common-cli.nix
    ./../modules/darwin/packages.nix
    ./../modules/home/programs/ghostty
  ];
}
