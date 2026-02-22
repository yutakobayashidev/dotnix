{ ... }:
{
  imports = [
    ./cli-minimal.nix
    ./../modules/linux/docker.nix
    ./../modules/linux/tailscale.nix
  ];

  home-manager.users.yuta.imports = [
    ./../modules/home/programs/common-cli.nix
    ./../modules/linux/home-packages.nix
  ];
}
